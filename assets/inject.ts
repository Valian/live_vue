import { h, reactive, provide, defineComponent } from "vue"
import type { LiveVueApp, LiveHook } from "./types.js"
import { liveInjectKey, hooksById } from "./use.js"
import { getProps, getSlots, getDiff, replaceSlotMap, type SlotMap } from "./attrs.js"
import { applyPatch } from "./jsonPatch.js"

type InjectionState = {
  component: any
  componentPromise: Promise<any> | null
  hook: LiveHook | null
  liveProxy: LiveHook
  props: Record<string, any>
  slots: SlotMap
  slotName: string
  targetId: string
}

export type InjectionHandle = {
  props: Record<string, any>
  slots: SlotMap
  register: () => void
}

const targetInjections = new Map<string, Map<string, Map<HTMLElement, InjectionState>>>()
const injectionStateByElement = new WeakMap<HTMLElement, InjectionState>()

const getHookSlots = (hook: LiveHook): SlotMap => (hook.vue.slots || {}) as SlotMap

const latestInjection = (states: Map<HTMLElement, InjectionState>) => Array.from(states.values()).at(-1) || null

const renderInjectionSlot = (state: InjectionState) => (slotProps: Record<string, any> = {}) =>
  h(
    defineComponent({
      setup(_, { slots: wrappedSlots }) {
        provide(liveInjectKey, state.liveProxy)
        return () => wrappedSlots.default?.()
      },
    }),
    null,
    { default: () => h(state.component, { ...slotProps, ...state.props }, state.slots) }
  )

export const syncTargetChain = (targetId: string | null) => {
  const seen = new Set<string>()
  let currentId = targetId

  while (currentId && !seen.has(currentId)) {
    seen.add(currentId)
    syncTargetSlots(currentId)
    currentId = hooksById.get(currentId)?.el.getAttribute("data-inject") || null
  }
}

const syncTargetSlots = (targetId: string) => {
  const targetHook = hooksById.get(targetId)
  if (!targetHook) return

  const injectionsBySlot = targetInjections.get(targetId) || new Map()
  const baseSlots = getSlots(targetHook.el as HTMLElement)
  const activeSlots = new Set<string>()

  replaceSlotMap(getHookSlots(targetHook), baseSlots)

  for (const [slotName, injections] of injectionsBySlot.entries()) {
    const state = latestInjection(injections)
    if (!state) continue
    getHookSlots(targetHook)[slotName] = renderInjectionSlot(state)
    activeSlots.add(slotName)
  }

  for (const slotName of Object.keys(getHookSlots(targetHook))) {
    if (!activeSlots.has(slotName) && !(slotName in baseSlots)) {
      delete getHookSlots(targetHook)[slotName]
    }
  }
}

const ensureInjectionState = async (
  el: HTMLElement,
  liveSocket: any,
  resolve: LiveVueApp["resolve"],
  hook: LiveHook | null = null
): Promise<InjectionState> => {
  const targetId = el.getAttribute("data-inject")
  const componentName = el.getAttribute("data-name")

  if (!targetId) {
    throw new Error("v-inject target id is required")
  }

  if (!componentName) {
    throw new Error("v-inject requires a v-component to inject")
  }

  let state = injectionStateByElement.get(el)

  if (!state) {
    const props = reactive(getProps(el, liveSocket))
    const slots = reactive(getSlots(el))
    applyPatch(props, getDiff(el, "data-streams-diff"))

    state = {
      component: null,
      componentPromise: null,
      hook,
      liveProxy: new Proxy({} as LiveHook, {
        get(_, key) {
          if (key === "el") return el
          if (key === "liveSocket") return hook?.liveSocket || liveSocket
          if (key === "vue") return hook?.vue || { props, slots, app: null }

          const liveHook = state?.hook
          const value = liveHook?.[key as keyof LiveHook]
          return typeof value === "function" ? value.bind(liveHook) : value
        },
      }),
      props,
      slots,
      slotName: el.getAttribute("data-inject-slot") || "default",
      targetId,
    }

    injectionStateByElement.set(el, state)
  } else {
    state.hook = hook
  }

  if (!state.componentPromise) {
    state.componentPromise = Promise.resolve(resolve(componentName)).then(component => {
      state!.component = component
      return component
    })
  }

  await state.componentPromise
  return state
}

const registerInjectionState = (el: HTMLElement, state: InjectionState) => {
  const slotInjections = targetInjections.get(state.targetId) || new Map()
  const states = slotInjections.get(state.slotName) || new Map()
  states.delete(el)
  states.set(el, state)
  slotInjections.set(state.slotName, states)
  targetInjections.set(state.targetId, slotInjections)
  syncTargetChain(state.targetId)
}

const unregisterInjectionState = (el: HTMLElement) => {
  const state = injectionStateByElement.get(el)
  if (!state) return

  const slotInjections = targetInjections.get(state.targetId)
  const states = slotInjections?.get(state.slotName)
  states?.delete(el)

  if (states && states.size === 0) {
    slotInjections?.delete(state.slotName)
  }

  if (slotInjections && slotInjections.size === 0) {
    targetInjections.delete(state.targetId)
  }

  syncTargetChain(state.targetId)
  injectionStateByElement.delete(el)
}

/**
 * Called from VueHook.mounted. If the element has `data-inject`, prepares the shared
 * reactive state and returns a handle with `props`, `slots`, and a `register` callback
 * to invoke once the hook's `vue` field and `hooksById` entry are in place. Returns
 * `null` for non-injected elements so the caller proceeds with the normal mount path.
 */
export const injectMounted = async (
  hook: LiveHook,
  liveSocket: any,
  resolve: LiveVueApp["resolve"]
): Promise<InjectionHandle | null> => {
  const el = hook.el as HTMLElement
  if (!el.getAttribute("data-inject")) return null

  const state = await ensureInjectionState(el, liveSocket, resolve, hook)

  return {
    props: state.props,
    slots: state.slots,
    register: () => registerInjectionState(el, state),
  }
}

/**
 * Ensures all injectors already in the DOM that point at `targetId` have
 * their state primed and registered. Called by the target's mount path so
 * that targets can render injected slots even when injectors mounted first.
 */
export const primeInjectionsForTarget = async (
  targetId: string | null,
  liveSocket: any,
  resolve: LiveVueApp["resolve"]
) => {
  if (!targetId) return

  const injections = Array.from(document.querySelectorAll<HTMLElement>("[data-inject]")).filter(
    el => el.getAttribute("data-inject") === targetId
  )

  await Promise.all(
    injections.map(async el => {
      const state = await ensureInjectionState(el, liveSocket, resolve)
      registerInjectionState(el, state)
    })
  )
}

/**
 * Called from VueHook.updated. If the element is an injector, re-syncs the slot
 * chain rooted at its target. No-op otherwise.
 */
export const injectUpdated = (el: HTMLElement) => {
  if (!el.getAttribute("data-inject")) return
  const state = injectionStateByElement.get(el)
  if (state) syncTargetChain(state.targetId)
}

/**
 * Called from VueHook.destroyed. Removes any injection registration associated
 * with the element and re-syncs the target chain so vacated slots clear.
 */
export const injectDestroyed = (el: HTMLElement) => {
  unregisterInjectionState(el)
}

import { createApp, createSSRApp, h, reactive, provide, defineComponent, type App } from "vue"
import { migrateToLiveVueApp } from "./app.js"
import type { ComponentMap, LiveVueApp, LiveVueOptions, LiveHook, Hook } from "./types.js"
import { liveInjectKey } from "./use.js"
import { mapValues, fromUtf8Base64 } from "./utils.js"
import { applyPatch, type Operation } from "./jsonPatch.js"

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

type SlotMap = Record<string, (slotProps?: Record<string, any>) => any>

const targetHooks = new Map<string, LiveHook>()
const targetInjections = new Map<string, Map<string, Map<HTMLElement, InjectionState>>>()
const injectionStateByElement = new WeakMap<HTMLElement, InjectionState>()

/**
 * Parses the JSON object from the element's attribute and returns them as an object.
 */
const getAttributeJson = (el: HTMLElement, attributeName: string): Record<string, any> | null => {
  const data = el.getAttribute(attributeName)
  return data ? JSON.parse(data) : null
}

/**
 * Parses the slots from the element's attributes and returns them as a record.
 * The slots are parsed from the "data-slots" attribute.
 * The slots are converted to a function that returns a div with the innerHTML set to the base64 decoded slot.
 */
const getSlots = (el: HTMLElement): SlotMap => {
  const dataSlots = getAttributeJson(el, "data-slots") || {}
  return mapValues(dataSlots, base64 => () => h("div", { innerHTML: fromUtf8Base64(base64).trim() }))
}

const getDiff = (el: HTMLElement, attributeName: string): Operation[] => {
  const dataPropsDiff = getAttributeJson(el, attributeName) || []
  return dataPropsDiff.map(([op, path, value]: [string, string, any]) => ({
    op,
    path,
    value,
  }))
}

/**
 * Parses the event handlers from the element's attributes and returns them as a record.
 * The handlers are parsed from the "data-handlers" attribute.
 * The handlers are converted to snake case and returned as a record.
 * A special case is made for the "JS.push" event, where the event is replaced with $event.
 * @param el - The element to parse the handlers from.
 * @param liveSocket - The LiveSocket instance.
 * @returns The handlers as an object.
 */
const getHandlers = (el: HTMLElement, liveSocket: any): Record<string, (event: any) => void> => {
  const handlers = getAttributeJson(el, "data-handlers") || {}
  const result: Record<string, (event: any) => void> = {}
  for (const handlerName in handlers) {
    const ops = handlers[handlerName]
    const snakeCaseName = `on${handlerName.charAt(0).toUpperCase() + handlerName.slice(1)}`
    result[snakeCaseName] = event => {
      // a little bit of magic to replace the event with the value of the input
      const parsedOps = JSON.parse(ops)
      const replacedOps = parsedOps.map(([op, args, ...other]: [string, any, ...any[]]) => {
        if (op === "push" && !args.value) args.value = event
        return [op, args, ...other]
      })
      liveSocket.execJS(el, JSON.stringify(replacedOps))
    }
  }
  return result
}

/**
 * Parses the props from the element's attributes and returns them as an object.
 * The props are parsed from the "data-props" attribute.
 * The props are merged with the event handlers from the "data-handlers" attribute.
 * @param el - The element to parse the props from.
 * @param liveSocket - The LiveSocket instance.
 * @returns The props as an object.
 */
const getProps = (el: HTMLElement, liveSocket: any): Record<string, any> => ({
  ...(getAttributeJson(el, "data-props") || {}),
  ...getHandlers(el, liveSocket),
})

const getElementId = (el: HTMLElement): string | null => el.id || el.getAttribute("id")
const replaceSlotMap = (target: SlotMap, next: SlotMap) => {
  for (const key of Object.keys(target)) {
    if (!(key in next)) delete target[key]
  }

  Object.assign(target, next)
}

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

const syncTargetChain = (targetId: string | null) => {
  const seen = new Set<string>()
  let currentId = targetId

  while (currentId && !seen.has(currentId)) {
    seen.add(currentId)
    syncTargetSlots(currentId)
    currentId = targetHooks.get(currentId)?.el.getAttribute("data-inject") || null
  }
}

const syncTargetSlots = (targetId: string) => {
  const targetHook = targetHooks.get(targetId)
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

const primeTargetInjections = async (
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

export const getVueHook = ({ resolve, setup }: LiveVueApp): Hook => ({
  async mounted() {
    const componentName = this.el.getAttribute("data-name")
    const injectTarget = this.el.getAttribute("data-inject")
    const componentPromise = Promise.resolve(componentName ? resolve(componentName) : null)
    let props = reactive(getProps(this.el, this.liveSocket))
    let slots = reactive(getSlots(this.el))

    if (injectTarget) {
      const state = await ensureInjectionState(this.el as HTMLElement, this.liveSocket, resolve, this as LiveHook)
      props = state.props
      slots = state.slots
    } else {
      // let's apply initial stream diff here, since all stream changes are sent in that attribute
      applyPatch(props, getDiff(this.el, "data-streams-diff"))
    }

    this.vue = { props, slots, app: null }
    ;(this.el as any).__liveVueHook = this
    const elementId = getElementId(this.el as HTMLElement)
    if (elementId) {
      targetHooks.set(elementId, this as LiveHook)
    }

    await primeTargetInjections(elementId, this.liveSocket, resolve)

    if (injectTarget) {
      const state = await ensureInjectionState(this.el as HTMLElement, this.liveSocket, resolve, this as LiveHook)
      registerInjectionState(this.el as HTMLElement, state)
    } else {
      const component = await componentPromise
      if (!component) return
      const makeApp = this.el.getAttribute("data-ssr") === "true" ? createSSRApp : createApp

      const app = setup({
        createApp: makeApp,
        component,
        props,
        slots,
        plugin: {
          install: (app: App) => {
            app.provide(liveInjectKey, this as LiveHook)
            app.config.globalProperties.$live = this as LiveHook
          },
        },
        el: this.el,
        ssr: false,
      })

      if (!app) throw new Error("Setup function did not return a Vue app!")

      this.vue.app = app
    }
  },
  updated() {
    if (this.el.getAttribute("data-use-diff") === "true") {
      applyPatch(this.vue.props, getDiff(this.el, "data-props-diff"))
    } else {
      Object.assign(this.vue.props, getProps(this.el, this.liveSocket))
    }
    // we're always applying streams diff, since all stream changes are sent in that attribute
    applyPatch(this.vue.props, getDiff(this.el, "data-streams-diff"))
    replaceSlotMap((this.vue.slots || {}) as SlotMap, getSlots(this.el))
    const elementId = getElementId(this.el as HTMLElement)

    if (elementId) {
      syncTargetChain(elementId)
    }

    if (this.el.getAttribute("data-inject")) {
      const state = injectionStateByElement.get(this.el as HTMLElement)
      if (state) {
        syncTargetChain(state.targetId)
      }
    }
  },
  destroyed() {
    unregisterInjectionState(this.el as HTMLElement)
    const elementId = getElementId(this.el as HTMLElement)
    if (elementId) {
      targetHooks.delete(elementId)
    }
    delete (this.el as any).__liveVueHook

    const instance = this.vue.app
    // TODO - is there maybe a better way to cleanup the app?
    if (instance) {
      window.addEventListener("phx:page-loading-stop", () => instance.unmount(), { once: true })
    }
  },
})

/**
 * Returns the hooks for the LiveVue app.
 * @param components - The components to use in the app.
 * @param options - The options for the LiveVue app.
 * @returns The hooks for the LiveVue app.
 */
type VueHooks = { VueHook: Hook }
type getHooksAppFn = (app: LiveVueApp) => VueHooks
type getHooksComponentsOptions = { initializeApp?: LiveVueOptions["setup"] }
type getHooksComponentsFn = (components: ComponentMap, options?: getHooksComponentsOptions) => VueHooks

export const getHooks: getHooksComponentsFn | getHooksAppFn = (
  componentsOrApp: ComponentMap | LiveVueApp,
  options?: getHooksComponentsOptions
) => {
  const app = migrateToLiveVueApp(componentsOrApp, options ?? {})
  return { VueHook: getVueHook(app) }
}

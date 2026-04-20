import { h, provide, defineComponent } from "vue"
import type { LiveHook } from "./types.js"
import { liveInjectKey, hooksById } from "./use.js"
import { getSlots, type SlotMap } from "./attrs.js"

type InjectorEntry = { targetId: string; slotName: string; component: any }
const injectors = new Map<string, InjectorEntry>()
const targetSlots = new Map<string, Map<string, string>>()

const getHookSlots = (hook: LiveHook): SlotMap => (hook.vue.slots || {}) as SlotMap

const renderInjectionSlot = (injectorId: string, component: any) => {
  const wrapper = defineComponent({
    setup(_, { slots: wrappedSlots }) {
      provide(liveInjectKey, hooksById.get(injectorId)!)
      return () => wrappedSlots.default?.()
    },
  })
  return (slotProps: Record<string, any> = {}) => {
    const hook = hooksById.get(injectorId)
    if (!hook) return null
    return h(wrapper, null, {
      default: () => h(component, { ...slotProps, ...hook.vue.props }, hook.vue.slots),
    })
  }
}

export const syncSlots = (targetId: string | null) => {
  if (!targetId) return
  const hook = hooksById.get(targetId)
  if (!hook) return

  const hookSlots = getHookSlots(hook)
  const baseSlots = getSlots(hook.el as HTMLElement)
  const injected = targetSlots.get(targetId)

  for (const key of Object.keys(hookSlots)) {
    if (!(key in baseSlots) && !injected?.has(key)) delete hookSlots[key]
  }

  for (const key of Object.keys(baseSlots)) {
    if (!injected?.has(key)) hookSlots[key] = baseSlots[key]
  }

  if (injected) {
    for (const [slotName, injectorId] of injected) {
      const entry = injectors.get(injectorId)
      if (entry) hookSlots[slotName] = renderInjectionSlot(injectorId, entry.component)
    }
  }
}

export const registerInjector = (id: string, targetId: string, slotName: string, component: any) => {
  injectors.set(id, { targetId, slotName, component })
  const slots = targetSlots.get(targetId) ?? new Map<string, string>()
  slots.set(slotName, id)
  targetSlots.set(targetId, slots)
  syncSlots(targetId)
}

export const unregisterInjector = (id: string) => {
  const entry = injectors.get(id)
  if (!entry) return
  injectors.delete(id)

  const slots = targetSlots.get(entry.targetId)
  if (slots?.get(entry.slotName) === id) slots.delete(entry.slotName)
  if (slots?.size === 0) targetSlots.delete(entry.targetId)

  syncSlots(entry.targetId)
}

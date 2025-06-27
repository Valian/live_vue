import { inject, onMounted, onUnmounted } from "vue"
import type { LiveHook } from "./types.js"

export const liveInjectKey = "_live_vue"

/**
 * Returns the LiveVue instance.
 * Can be used to access the LiveVue instance from within a LiveVue component.
 * It allows to e.g. push events to the LiveView.
 */
export const useLiveVue = (): LiveHook => {
  const live = inject<LiveHook>(liveInjectKey)
  if (!live) throw new Error("LiveVue not provided. Are you using this inside a LiveVue component?")
  return live
}

/**
 * Registers a callback to be called when an event is received from the server.
 * It automatically removes the callback when the component is unmounted.
 * @param event - The event name.
 * @param callback - The callback to call when the event is received.
 */
export function useLiveEvent<T>(event: string, callback: (data: T) => void) {
  let callbackRef: ReturnType<LiveHook["handleEvent"]> | null = null
  onMounted(() => {
    const live = useLiveVue()
    callbackRef = live.handleEvent(event, callback)
  })
  onUnmounted(() => {
    const live = useLiveVue()
    if (callbackRef) live.removeHandleEvent(callbackRef)
    callbackRef = null
  })
}

import { inject } from "vue"
import type { Live } from "./types"

export const liveInjectKey = "_live_vue"

/**
 * Returns the LiveVue instance.
 * Can be used to access the LiveVue instance from within a LiveVue component.
 * It allows to e.g. push events to the LiveView.
 */
export const useLiveVue = (): Live => {
    const live = inject<Live>(liveInjectKey)
    if (!live) throw new Error("LiveVue not provided. Are you using this inside a LiveVue component?")
    return live
}

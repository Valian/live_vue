import { inject } from "vue"
import { Live } from "./index"

export const liveInjectKey = '_live_vue'

export const useLiveVue = (): Live => {
  const live = inject<Live>(liveInjectKey)
  if (!live) throw new Error("LiveVue not provided. Are you using this inside a LiveVue component?")
  return live
}
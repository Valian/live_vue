import {inject} from "vue"

export const liveInjectKey = '_live_vue'

export function useLiveVue() {
  // provided by hook
  return inject(liveInjectKey)
}
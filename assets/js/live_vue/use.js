import {inject} from "vue"

export const liveInjectKey = Symbol()

export function useLiveVue() {
  // provided by hook
  return inject(liveInjectKey)
}
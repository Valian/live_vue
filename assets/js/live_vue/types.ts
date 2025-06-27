import type { LiveSocketInstanceInterface, ViewHook } from "../../../deps/phoenix_live_view/assets/js/types"
import type { App, Component, createApp, createSSRApp, h, Plugin } from "vue"
export type { Hook } from "../../../deps/phoenix_live_view/assets/js/types"

export type ComponentOrComponentModule = Component | { default: Component }
export type ComponentOrComponentPromise = ComponentOrComponentModule | Promise<ComponentOrComponentModule>
export type ComponentMap = Record<string, ComponentOrComponentPromise>

export type VueComponent = ComponentOrComponentPromise

type VueComponentInternal = Parameters<typeof h>[0]
type VuePropsInternal = Parameters<typeof h>[1]
type VueSlotsInternal = Parameters<typeof h>[2]

export type VueArgs = {
  props: VuePropsInternal
  slots: VueSlotsInternal
  app: App<Element>
}

// all the functions and additional properties that are available on the LiveHook
export type LiveHook = ViewHook & { vue: VueArgs; liveSocket: LiveSocketInstanceInterface }

export interface SetupContext {
  createApp: typeof createSSRApp | typeof createApp
  component: VueComponentInternal
  props: Record<string, unknown>
  slots: Record<string, () => unknown>
  plugin: Plugin<[]>
  el: Element
  ssr: boolean
}

export type LiveVueOptions = {
  resolve: (path: string) => ComponentOrComponentPromise | undefined | null
  setup?: (context: SetupContext) => App
}

export type LiveVueApp = {
  setup: (context: SetupContext) => App
  resolve: (path: string) => ComponentOrComponentPromise
}

export interface LiveVue {
  VueHook: ViewHook
}

import type { App, Component, createApp, createSSRApp, Reactive } from "vue"

export type ComponentOrComponentModule = Component | { default: Component }
export type ComponentOrComponentPromise = ComponentOrComponentModule | Promise<ComponentOrComponentModule>
export type ComponentMap = Record<string, ComponentOrComponentPromise>

export type LiveHook = {
  vue: {
    props: Reactive<Record<string, any>>
    slots: Reactive<Record<string, () => any>>
    // App<Element>, just not working in SSR context
    app: App<any>
  }
  // HTMLDivElement, just not working in SSR context
  el: any
  liveSocket: any
  pushEvent(event: string, payload?: object, onReply?: (reply: any, ref: number) => void): number
  pushEventTo(phxTarget: any, event: string, payload?: object, onReply?: (reply: any, ref: number) => void): number
  handleEvent(event: string, callback: (payload: any) => void): Function
  removeHandleEvent(callbackRef: Function): void
  upload(name: string, files: any): void
  uploadTo(phxTarget: any, name: string, files: any): void
}

export type SetupContext = {
  createApp: typeof createSSRApp | typeof createApp
  component: Component
  props: Record<string, any>
  slots: Record<string, () => any>
  plugin: { install: (app: App) => void }
  el: any
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

export type LiveVue = {
  [key: string]: (this: LiveHook, ...args: any[]) => any
}

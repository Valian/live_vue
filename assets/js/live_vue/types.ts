import type { App, Component, createApp, createSSRApp, Reactive } from "vue"

export type Live = {
  vue: {
    props: Reactive<Record<string, any>>,
    slots: Reactive<Record<string, () => any>>,
    app: App<Element>
  }
  el: HTMLDivElement
  liveSocket: any
  pushEvent(event: string, payload?: object, onReply?: (reply: any, ref: number) => void): number
  pushEventTo(phxTarget: any, event: string, payload?: object, onReply?: (reply: any, ref: number) => void): number
  handleEvent(event: string, callback: (payload: any) => void): Function
  removeHandleEvent(callbackRef: Function): void
  upload(name: string, files: any): void
  uploadTo(phxTarget: any, name: string, files: any): void
}

export type InitializeAppArgs = {
  createApp: typeof createSSRApp | typeof createApp;
  component: Component;
  props: any;
  slots: Record<string, () => any>;
  plugin: {install: (app: App) => void};
  el: HTMLElement
}

export type LiveVueOptions = {
  initializeApp?: (args: InitializeAppArgs) => App
}

export type LiveVue = {
  [key: string]: (this: Live, ...args: any[]) => any
}
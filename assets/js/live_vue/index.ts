import { type App, createSSRApp, createApp, Ref, Reactive } from 'vue'

export { getHooks, initializeVueApp } from "./hooks"
export { useLiveVue } from "./use"

export type Live = {
    el: HTMLDivElement & {_props: Reactive<Record<string, any>>, _slots: Reactive<Record<string, () => any>>}
    liveSocket: any
    pushEvent(event: string, payload?: object, onReply?: (reply: any, ref: number) => void): number
    pushEventTo(phxTarget: any, event: string, payload?: object, onReply?: (reply: any, ref: number) => void): number
    handleEvent(event: string, callback: (payload: any) => void): Function
    removeHandleEvent(callbackRef: Function): void
    upload(name: string, files: any): void
    uploadTo(phxTarget: any, name: string, files: any): void
}

export type LiveVue = {
    [key: string]: (this: Live, ...args: any[]) => any
}

export type InitializeAppFn = (args: {
    createApp: typeof createSSRApp | typeof createApp;
    component: any;
    props: any;
    slots: Record<string, () => any>;
    plugin: {install: (app: App) => void};
    el: HTMLElement
}) => App

export interface Options {
    initializeApp?: InitializeAppFn
}
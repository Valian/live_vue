import {type App, createSSRApp, createApp} from 'vue'

export type Live = {
    // in case of LiveView, el is always a div
    el: HTMLDivElement

    pushEvent(event: string, payload?: object, onReply?: (reply: any, ref: number) => void): number
    pushEventTo(phxTarget: any, event: string, payload?: object, onReply?: (reply: any, ref: number) => void): number

    handleEvent(event: string, callback: (payload: any) => void): Function
    removeHandleEvent(callbackRef: Function): void

    upload(name: string, files: any): void
    uploadTo(phxTarget: any, name: string, files: any): void
}

type InitializeAppFn = (args: {
    createApp: typeof createSSRApp | typeof createApp;
    component: any;
    props: any;
    slots: HTMLElement;
    plugin: {install: (app: App) => App};
    el: HTMLElement
}) => App

interface Options  {
    initializeApp?: InitializeAppFn
}

export declare const useLiveVue: () => Live
export declare const getHooks: (components: object, options: Options) => {LiveVue: any}
export declare const initializeVueApp: InitializeAppFn
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

export declare const useLiveVue: () => Live
export declare const getHooks: (components: object) => {LiveVue: any}

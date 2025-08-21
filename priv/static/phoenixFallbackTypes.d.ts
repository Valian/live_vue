type GetPhoenixSocket<T> = T extends {
    Socket: infer S;
} ? S : any;
type PhoenixSocket = GetPhoenixSocket<typeof import("phoenix")>;
type ServerHTMLElement = unknown extends HTMLElement ? any : HTMLElement;
type ServerEvent = unknown extends Event ? any : Event;
type ServerFileList = unknown extends FileList ? any : FileList;
declare global {
    interface HTMLElement {
    }
    interface Event {
    }
    interface FileList {
    }
}
export interface LiveSocketInstanceInterface {
    version(): string;
    isProfileEnabled(): boolean;
    isDebugEnabled(): boolean;
    isDebugDisabled(): boolean;
    enableDebug(): void;
    enableProfiling(): void;
    disableDebug(): void;
    disableProfiling(): void;
    enableLatencySim(upperBoundMs: number): void;
    disableLatencySim(): void;
    getLatencySim(): number | null;
    getSocket(): PhoenixSocket;
    connect(): void;
    disconnect(callback?: () => void): void;
    replaceTransport(transport: any): void;
    execJS(el: ServerHTMLElement, encodedJS: string, eventType?: string | null): void;
    js(): any;
    pushHistoryPatch(event: ServerEvent, href: string, kind: string, el: any): void;
    historyRedirect(event: ServerEvent, href: string, kind: string, el: any, callback: any): void;
}
export type OnReply = (reply: any, ref: number) => any;
export type CallbackRef = {
    event: string;
    callback: (payload: any) => any;
};
export type PhxTarget = string | number | ServerHTMLElement;
export interface HookInterface {
    el: ServerHTMLElement;
    liveSocket: LiveSocketInstanceInterface;
    mounted?: () => void;
    beforeUpdate?: () => void;
    updated?: () => void;
    destroyed?: () => void;
    disconnected?: () => void;
    reconnected?: () => void;
    js(): any;
    pushEvent(event: string, payload: any, onReply: OnReply): void;
    pushEvent(event: string, payload?: any): Promise<any>;
    pushEventTo(selectorOrTarget: PhxTarget, event: string, payload: object, onReply: OnReply): void;
    pushEventTo(selectorOrTarget: PhxTarget, event: string, payload?: object): Promise<PromiseSettledResult<{
        reply: any;
        ref: number;
    }>[]>;
    handleEvent(event: string, callback: (payload: any) => any): CallbackRef;
    removeHandleEvent(ref: CallbackRef): void;
    upload(name: any, files: any): any;
    uploadTo(selectorOrTarget: PhxTarget, name: any, files: any): any;
    [key: PropertyKey]: any;
}
export interface Hook<T = object> {
    mounted?: (this: T & HookInterface) => void;
    beforeUpdate?: (this: T & HookInterface) => void;
    updated?: (this: T & HookInterface) => void;
    destroyed?: (this: T & HookInterface) => void;
    disconnected?: (this: T & HookInterface) => void;
    reconnected?: (this: T & HookInterface) => void;
    [key: PropertyKey]: any;
}
export declare class ViewHook implements HookInterface {
    el: ServerHTMLElement;
    liveSocket: LiveSocketInstanceInterface;
    static makeID(): number;
    static elementID(el: ServerHTMLElement): any;
    constructor(view: any | null, el: ServerHTMLElement, callbacks?: Hook);
    mounted(): void;
    beforeUpdate(): void;
    updated(): void;
    destroyed(): void;
    disconnected(): void;
    reconnected(): void;
    js(): any;
    pushEvent(event: string, payload?: any, onReply?: OnReply): Promise<any>;
    pushEventTo(selectorOrTarget: PhxTarget, event: string, payload?: object, onReply?: OnReply): Promise<PromiseSettledResult<{
        reply: any;
        ref: any;
    }>[]>;
    handleEvent(event: string, callback: (payload: any) => any): CallbackRef;
    removeHandleEvent(ref: CallbackRef): void;
    upload(name: string, files: ServerFileList): any;
    uploadTo(selectorOrTarget: PhxTarget, name: string, files: ServerFileList): any;
}
export {};

import type { App, Component, createApp, createSSRApp, h, Plugin } from "vue";
import type { LiveSocketInstanceInterface as PhoenixLiveSocketInstanceInterface, ViewHook as PhoenixViewHook, Hook as PhoenixHook } from "phoenix_live_view";
import type { LiveSocketInstanceInterface as FallbackLiveSocketInstanceInterface, ViewHook as FallbackViewHook, Hook as FallbackHook } from "./phoenixFallbackTypes";
export type LiveSocketInstanceInterface = PhoenixLiveSocketInstanceInterface extends undefined ? FallbackLiveSocketInstanceInterface : PhoenixLiveSocketInstanceInterface;
export type ViewHook = PhoenixViewHook extends undefined ? FallbackViewHook : PhoenixViewHook;
export type Hook = PhoenixHook extends undefined ? FallbackHook : PhoenixHook;
export type ComponentOrComponentModule = Component | {
    default: Component;
};
export type ComponentOrComponentPromise = ComponentOrComponentModule | Promise<ComponentOrComponentModule>;
export type ComponentMap = Record<string, ComponentOrComponentPromise>;
export type VueComponent = ComponentOrComponentPromise;
type VueComponentInternal = Parameters<typeof h>[0];
type VuePropsInternal = Parameters<typeof h>[1];
type VueSlotsInternal = Parameters<typeof h>[2];
export type VueArgs = {
    props: VuePropsInternal;
    slots: VueSlotsInternal;
    app: App<Element>;
};
export type LiveHook = ViewHook & {
    vue: VueArgs;
    liveSocket: LiveSocketInstanceInterface;
};
export interface UploadEntry {
    ref: string;
    client_name: string;
    client_size: number;
    client_type: string;
    progress: number;
    done: boolean;
    valid: boolean;
    preflighted: boolean;
    errors: string[];
}
export interface UploadConfig {
    ref: string;
    name: string;
    accept: string | false;
    max_entries: number;
    auto_upload: boolean;
    entries: UploadEntry[];
    errors: {
        ref: string;
        error: string;
    }[];
}
export type UploadOptions = {
    changeEvent?: string;
    submitEvent: string;
};
export interface AsyncResult<T = unknown> {
    ok: boolean;
    loading: string[] | null;
    failed: any | null;
    result: T | null;
}
export interface SetupContext {
    createApp: typeof createSSRApp | typeof createApp;
    component: VueComponentInternal;
    props: Record<string, unknown>;
    slots: Record<string, () => unknown>;
    plugin: Plugin<[]>;
    el: Element;
    ssr: boolean;
}
export type LiveVueOptions = {
    resolve: (path: string) => ComponentOrComponentPromise | undefined | null;
    setup?: (context: SetupContext) => App;
};
export type LiveVueApp = {
    setup: (context: SetupContext) => App;
    resolve: (path: string) => ComponentOrComponentPromise;
};
export interface LiveVue {
    VueHook: ViewHook;
}
export {};

import type { LiveSocket, ViewHook, ViewHookInternal } from "phoenix_live_view";
import type { App, Component, createApp, createSSRApp, h, Plugin } from "vue";
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
export type LiveHook = ViewHookInternal & {
    vue: VueArgs;
    liveSocket: LiveSocket;
};
export type LiveHookInternal = ViewHook<{
    vue: VueArgs;
    liveSocket: LiveSocket;
}>;
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

import { type App, type Component } from "vue";
import type { SetupContext, LiveVueOptions, ComponentMap, LiveVueApp } from "./types.js";
/**
 * Initializes a Vue app with the given options and mounts it to the specified element.
 * It's a default implementation of the `setup` option, which can be overridden.
 * If you want to override it, simply provide your own implementation of the `setup` option.
 */
export declare const defaultSetup: ({ createApp, component, props, slots, plugin, el }: SetupContext) => App<Element>;
export declare const migrateToLiveVueApp: (components: ComponentMap, options?: {
    initializeApp?: (context: SetupContext) => App;
}) => LiveVueApp;
export declare const createLiveVue: ({ resolve, setup }: LiveVueOptions) => {
    setup: (context: SetupContext) => App;
    resolve: (path: string) => Promise<Component>;
};

import { ComponentMap, LiveVueApp, LiveVueOptions, Hook } from "./types.js";
export declare const getVueHook: ({ resolve, setup }: LiveVueApp) => Hook;
/**
 * Returns the hooks for the LiveVue app.
 * @param components - The components to use in the app.
 * @param options - The options for the LiveVue app.
 * @returns The hooks for the LiveVue app.
 */
type VueHooks = {
    VueHook: Hook;
};
type getHooksAppFn = (app: LiveVueApp) => VueHooks;
type getHooksComponentsOptions = {
    initializeApp?: LiveVueOptions["setup"];
};
type getHooksComponentsFn = (components: ComponentMap, options?: getHooksComponentsOptions) => VueHooks;
export declare const getHooks: getHooksComponentsFn | getHooksAppFn;
export {};

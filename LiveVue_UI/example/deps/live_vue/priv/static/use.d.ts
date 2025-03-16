import type { LiveHook } from "./types.js";
export declare const liveInjectKey = "_live_vue";
/**
 * Returns the LiveVue instance.
 * Can be used to access the LiveVue instance from within a LiveVue component.
 * It allows to e.g. push events to the LiveView.
 */
export declare const useLiveVue: () => LiveHook;

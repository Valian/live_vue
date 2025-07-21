import type { LiveHook } from "./types.js";
export declare const liveInjectKey = "_live_vue";
/**
 * Returns the LiveVue instance.
 * Can be used to access the LiveVue instance from within a LiveVue component.
 * It allows to e.g. push events to the LiveView.
 */
export declare const useLiveVue: () => LiveHook;
/**
 * Registers a callback to be called when an event is received from the server.
 * It automatically removes the callback when the component is unmounted.
 * @param event - The event name.
 * @param callback - The callback to call when the event is received.
 */
export declare function useLiveEvent<T>(event: string, callback: (data: T) => void): void;
/**
 * A composable for navigation.
 * It uses the LiveSocket instance to navigate to a new location.
 * Works in the same way as the `live_patch` and `live_redirect` functions in LiveView.
 * @returns An object with `patch` and `navigate` functions.
 */
export declare const useLiveNavigation: () => {
    patch: (hrefOrQueryParams: string | Record<string, string>, opts?: {
        replace?: boolean;
    }) => void;
    navigate: (href: string, opts?: {
        replace?: boolean;
    }) => void;
};

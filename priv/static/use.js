import { inject, onMounted, onUnmounted } from "vue";
export const liveInjectKey = "_live_vue";
/**
 * Returns the LiveVue instance.
 * Can be used to access the LiveVue instance from within a LiveVue component.
 * It allows to e.g. push events to the LiveView.
 */
export const useLiveVue = () => {
    const live = inject(liveInjectKey);
    if (!live)
        throw new Error("LiveVue not provided. Are you using this inside a LiveVue component?");
    return live;
};
/**
 * Registers a callback to be called when an event is received from the server.
 * It automatically removes the callback when the component is unmounted.
 * @param event - The event name.
 * @param callback - The callback to call when the event is received.
 */
export function useLiveEvent(event, callback) {
    let callbackRef = null;
    onMounted(() => {
        const live = useLiveVue();
        callbackRef = live.handleEvent(event, callback);
    });
    onUnmounted(() => {
        const live = useLiveVue();
        if (callbackRef)
            live.removeHandleEvent(callbackRef);
        callbackRef = null;
    });
}
/**
 * A composable for navigation.
 * It uses the LiveSocket instance to navigate to a new location.
 * Works in the same way as the `live_patch` and `live_redirect` functions in LiveView.
 * @returns An object with `patch` and `navigate` functions.
 */
export const useLiveNavigation = () => {
    const live = useLiveVue();
    const liveSocket = live.liveSocket;
    if (!liveSocket)
        throw new Error("LiveSocket not initialized");
    /**
     * Patches the current LiveView.
     * @param hrefOrQueryParams - The URL or query params to navigate to.
     * @param opts - The options for the navigation.
     */
    const patch = (hrefOrQueryParams, opts = {}) => {
        let href = typeof hrefOrQueryParams === "string" ? hrefOrQueryParams : window.location.pathname;
        if (typeof hrefOrQueryParams === "object") {
            const queryParams = new URLSearchParams(hrefOrQueryParams);
            href = `${href}?${queryParams.toString()}`;
        }
        liveSocket.pushHistoryPatch(new Event("click"), href, opts.replace ? "replace" : "push", null);
    };
    /**
     * Navigates to a new location.
     * @param href - The URL to navigate to.
     * @param opts - The options for the navigation.
     */
    const navigate = (href, opts = {}) => {
        liveSocket.historyRedirect(new Event("click"), href, opts.replace ? "replace" : "push", null, null);
    };
    return {
        patch,
        navigate,
    };
};

declare const _default: import("vue").DefineComponent<import("vue").ExtractPropTypes<{
    /**
     * Uses traditional browser navigation to the new location.
     * This means the whole page is reloaded on the browser.
     */
    href: {
        type: StringConstructor;
        default: null;
    };
    /**
     * Patches the current LiveView.
     * The `handle_params` callback of the current LiveView will be invoked and the minimum content
     * will be sent over the wire, as any other LiveView diff.
     */
    patch: {
        type: StringConstructor;
        default: null;
    };
    /**
     * Navigates to a LiveView.
     * When redirecting across LiveViews, the browser page is kept, but a new LiveView process
     * is mounted and its contents is loaded on the page. It is only possible to navigate
     * between LiveViews declared under the same router
     * [`live_session`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html#live_session/3).
     * When used outside of a LiveView or across live sessions, it behaves like a regular
     * browser redirect.
     */
    navigate: {
        type: StringConstructor;
        default: null;
    };
    /**
     * When using `:patch` or `:navigate`,
     * should the browser's history be replaced with `pushState`?
     */
    replace: {
        type: BooleanConstructor;
        default: boolean;
    };
}>, () => import("vue").VNode<import("vue").RendererNode, import("vue").RendererElement, {
    [key: string]: any;
}>, {}, {}, {}, import("vue").ComponentOptionsMixin, import("vue").ComponentOptionsMixin, {}, string, import("vue").PublicProps, Readonly<import("vue").ExtractPropTypes<{
    /**
     * Uses traditional browser navigation to the new location.
     * This means the whole page is reloaded on the browser.
     */
    href: {
        type: StringConstructor;
        default: null;
    };
    /**
     * Patches the current LiveView.
     * The `handle_params` callback of the current LiveView will be invoked and the minimum content
     * will be sent over the wire, as any other LiveView diff.
     */
    patch: {
        type: StringConstructor;
        default: null;
    };
    /**
     * Navigates to a LiveView.
     * When redirecting across LiveViews, the browser page is kept, but a new LiveView process
     * is mounted and its contents is loaded on the page. It is only possible to navigate
     * between LiveViews declared under the same router
     * [`live_session`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html#live_session/3).
     * When used outside of a LiveView or across live sessions, it behaves like a regular
     * browser redirect.
     */
    navigate: {
        type: StringConstructor;
        default: null;
    };
    /**
     * When using `:patch` or `:navigate`,
     * should the browser's history be replaced with `pushState`?
     */
    replace: {
        type: BooleanConstructor;
        default: boolean;
    };
}>> & Readonly<{}>, {
    replace: boolean;
    patch: string;
    href: string;
    navigate: string;
}, {}, {}, {}, string, import("vue").ComponentProvideOptions, true, {}, any>;
export default _default;

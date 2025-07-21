import { computed, defineComponent, h } from "vue";
export default defineComponent({
    props: {
        /**
         * Uses traditional browser navigation to the new location.
         * This means the whole page is reloaded on the browser.
         */
        href: {
            type: String,
            default: null,
        },
        /**
         * Patches the current LiveView.
         * The `handle_params` callback of the current LiveView will be invoked and the minimum content
         * will be sent over the wire, as any other LiveView diff.
         */
        patch: {
            type: String,
            default: null,
        },
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
            type: String,
            default: null,
        },
        /**
         * When using `:patch` or `:navigate`,
         * should the browser's history be replaced with `pushState`?
         */
        replace: {
            type: Boolean,
            default: false,
        },
    },
    setup(props, { attrs, slots }) {
        const linkAttrs = computed(() => {
            if (!props.patch && !props.navigate) {
                return {
                    href: props.href || "#",
                };
            }
            return {
                href: (props.navigate ? props.navigate : props.patch) || "#",
                "data-phx-link": props.navigate ? "redirect" : "patch",
                "data-phx-link-state": props.replace ? "replace" : "push",
            };
        });
        return () => {
            return h("a", {
                ...attrs,
                ...linkAttrs.value,
            }, slots);
        };
    },
});

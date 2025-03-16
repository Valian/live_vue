import { createApp, createSSRApp, h, reactive } from "vue";
import { migrateToLiveVueApp } from "./app.js";
import { liveInjectKey } from "./use.js";
import { mapValues } from "./utils.js";
/**
 * Parses the JSON object from the element's attribute and returns them as an object.
 */
const getAttributeJson = (el, attributeName) => {
    const data = el.getAttribute(attributeName);
    return data ? JSON.parse(data) : {};
};
/**
 * Parses the slots from the element's attributes and returns them as a record.
 * The slots are parsed from the "data-slots" attribute.
 * The slots are converted to a function that returns a div with the innerHTML set to the base64 decoded slot.
 */
const getSlots = (el) => {
    const dataSlots = getAttributeJson(el, "data-slots");
    return mapValues(dataSlots, base64 => () => h("div", { innerHTML: atob(base64).trim() }));
};
/**
 * Parses the event handlers from the element's attributes and returns them as a record.
 * The handlers are parsed from the "data-handlers" attribute.
 * The handlers are converted to snake case and returned as a record.
 * A special case is made for the "JS.push" event, where the event is replaced with $event.
 * @param el - The element to parse the handlers from.
 * @param liveSocket - The LiveSocket instance.
 * @returns The handlers as an object.
 */
const getHandlers = (el, liveSocket) => {
    const handlers = getAttributeJson(el, "data-handlers");
    const result = {};
    for (const handlerName in handlers) {
        const ops = handlers[handlerName];
        const snakeCaseName = `on${handlerName.charAt(0).toUpperCase() + handlerName.slice(1)}`;
        result[snakeCaseName] = event => {
            // a little bit of magic to replace the event with the value of the input
            const parsedOps = JSON.parse(ops);
            const replacedOps = parsedOps.map(([op, args, ...other]) => {
                if (op === "push" && !args.value)
                    args.value = event;
                return [op, args, ...other];
            });
            liveSocket.execJS(el, JSON.stringify(replacedOps));
        };
    }
    return result;
};
/**
 * Parses the props from the element's attributes and returns them as an object.
 * The props are parsed from the "data-props" attribute.
 * The props are merged with the event handlers from the "data-handlers" attribute.
 * @param el - The element to parse the props from.
 * @param liveSocket - The LiveSocket instance.
 * @returns The props as an object.
 */
const getProps = (el, liveSocket) => ({
    ...getAttributeJson(el, "data-props"),
    ...getHandlers(el, liveSocket),
});
export const getVueHook = ({ resolve, setup }) => ({
    async mounted() {
        const componentName = this.el.getAttribute("data-name");
        const component = await resolve(componentName);
        const makeApp = this.el.getAttribute("data-ssr") === "true" ? createSSRApp : createApp;
        const props = reactive(getProps(this.el, this.liveSocket));
        const slots = reactive(getSlots(this.el));
        const app = setup({
            createApp: makeApp,
            component,
            props,
            slots,
            plugin: { install: (app) => app.provide(liveInjectKey, this) },
            el: this.el,
            ssr: false,
        });
        if (!app)
            throw new Error("Setup function did not return a Vue app!");
        this.vue = { props, slots, app };
    },
    updated() {
        Object.assign(this.vue.props ?? {}, getProps(this.el, this.liveSocket));
        Object.assign(this.vue.slots ?? {}, getSlots(this.el));
    },
    destroyed() {
        const instance = this.vue.app;
        // TODO - is there maybe a better way to cleanup the app?
        if (instance) {
            window.addEventListener("phx:page-loading-stop", () => instance.unmount(), { once: true });
        }
    },
});
export const getHooks = (componentsOrApp, options) => {
    const app = migrateToLiveVueApp(componentsOrApp, options ?? {});
    return { VueHook: getVueHook(app) };
};

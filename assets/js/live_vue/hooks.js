import { createApp, createSSRApp, reactive, h } from 'vue'
import { liveInjectKey } from "./use.js"
import { normalizeComponents, getComponent } from './components.js';


function mapValues(object, cb) {
    return Object.entries(object).reduce((acc, [key, value]) => {
        acc[key] = cb(value, key, object);
        return acc;
    }, {});
}

function getAttributeJson(el, attributeName) {
    const data = el.getAttribute(attributeName)
    return data ? JSON.parse(data) : {}
}

function getSlots(el) {
    const dataSlots = getAttributeJson(el, "data-slots")
    return mapValues(
        dataSlots, 
        base64 => () => h('div', {innerHTML: atob(base64).trim()})
    )
}

function getHandlers(el, liveSocket) {
    const handlers = getAttributeJson(el, "data-handlers")
    const result = {}
    for (const handlerName in handlers) {
        const ops = handlers[handlerName]
        const snakeCaseName = `on${handlerName.charAt(0).toUpperCase() + handlerName.slice(1)}`
        result[snakeCaseName] = (event) => {
            // a little bit of magic to replace the event with the value of the input
            const parsedOps = JSON.parse(ops)
            const replacedOps = parsedOps.map(([op, args, ...other]) => {
                if (op === 'push' && !args.value) args.value = event
                return [op, args, ...other]
            })
            liveSocket.execJS(el, JSON.stringify(replacedOps))
        }
    }
    return result
}

function getProps(el, liveSocket) {
    return {
        ...getAttributeJson(el, "data-props"),
        ...getHandlers(el, liveSocket),
    }
}

/**
 * Initializes a Vue app with the given options and mounts it to the specified element.
 * It's a default implementation of the `initializeApp` hook option, which can be overridden.
 */
export const initializeVueApp = ({createApp, component, props, slots, plugin, el}) => {
    const renderFn = () => h(component, props, slots)
    const app = createApp({ render: renderFn });
    app.use(plugin);
    app.mount(el);
    return app;
}

export function getHooks(components, options = {}) {
    const initializeApp = options.initializeApp || initializeVueApp
    components = normalizeComponents(components)

    const VueHook = {
        async mount(el, liveSocket) {
            const componentName = el.getAttribute("data-name")
            const component = await getComponent(components, componentName)

            const makeApp = el.getAttribute("data-ssr") === "true" ? createSSRApp : createApp

            el._props = reactive(getProps(el, liveSocket))
            el._slots = reactive(getSlots(el))
            
            const initializeContext = {
                createApp: makeApp,
                component: component,
                props: el._props,
                slots: el._slots,
                plugin: { install: (app) => app.provide(liveInjectKey, this) },
                el: el
            }

            const app = initializeApp(initializeContext)
            if (!app) throw new Error("Custom initialize app function did not return an app")

            el._instance = app
        },
        mounted() {
            this.mount(this.el, this.liveSocket)
        },
        updated() {
            Object.assign(this.el._props, getProps(this.el, this.liveSocket))
            Object.assign(this.el._slots, getSlots(this.el))
        },
        destroyed() {
            const instance = this.el._instance
            if (instance) {
                window.addEventListener("phx:page-loading-stop", () => instance.unmount(), {once: true})
            }
        },
    }

    return {
        VueHook,
    }
}

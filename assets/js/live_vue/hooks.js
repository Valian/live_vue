import { createApp, createSSRApp, reactive, h } from 'vue'
import { liveInjectKey } from "./use"
import { normalizeComponents, getComponent } from './components';


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

export const initializeVueApp = ({createApp, component, props, slots, plugin, el}) => {
    return createApp({ render: () => h(component, props, slots) })
      .use(plugin)
      .mount(el)
  }

export function getHooks(components, options = {}) {
    components = normalizeComponents(components)

    const VueHook = {
        async mount(el, liveSocket) {
            const componentName = el.getAttribute("data-name")
            const component = await getComponent(components, componentName)

            const makeApp = el.getAttribute("data-ssr") === "true" ? createSSRApp : createApp

            el._props = reactive(getProps(el, liveSocket))
            el._slots = reactive(getSlots(el))
            
            const initializeApp = options.initializeApp || initializeVueApp
            el._instance = initializeApp({
            createApp: makeApp,
            component: component,
            props: el._props,
            slots: el._slots,
            plugin: { install: (app) => app.provide(liveInjectKey, this) },
            el: el
            })
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

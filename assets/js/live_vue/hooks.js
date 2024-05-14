import { createApp, createSSRApp, reactive, h, ref, computed } from 'vue'
import { liveInjectKey } from "./use"


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

export function getHooks(components) {
    const VueHook = {
        mount(el, liveSocket) {
            const componentName = el.getAttribute("data-name")
            const component = components[componentName]
            
            if (!component) {
                console.error(`Component ${componentName} not found`)
                return
            }

            const makeApp = el.getAttribute("data-ssr") === "true" ? createSSRApp : createApp

            el._props = reactive(getProps(el, liveSocket))
            el._slots = reactive(getSlots(el))
            
            el._instance = makeApp({ render: () => h(component, el._props, el._slots) })
            el._instance.provide(liveInjectKey, this)
            el._instance.mount(el)
        },
        mounted() {
            this.mount(this.el, this.liveSocket)
        },
        updated() {
            Object.assign(this.el._props, getProps(this.el, this.liveSocket))
            Object.assign(this.el._slots, getSlots(this.el))
        },
        destroyed() {
            window.addEventListener("phx:page-loading-stop", () => this.el._instance.unmount(), {once: true})
        },
    }

    return {
        VueHook,
    }
}

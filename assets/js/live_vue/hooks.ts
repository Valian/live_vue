import { createApp, createSSRApp, reactive, h, type App } from "vue"
import { liveInjectKey } from "./use"
import { normalizeComponents, getComponent } from "./components"
import { InitializeAppFn, LiveVue, Options } from "./index"

const mapValues = <T, U>(object: Record<string, T>, cb: (value: T, key: string, object: Record<string, T>) => U): Record<string, U> =>
    Object.entries(object).reduce((acc, [key, value]) => {
        acc[key] = cb(value, key, object)
        return acc
    }, {} as Record<string, U>)

const getAttributeJson = (el: HTMLElement, attributeName: string): Record<string, any> => {
    const data = el.getAttribute(attributeName)
    return data ? JSON.parse(data) : {}
}

const getSlots = (el: HTMLElement): Record<string, () => any> => {
    const dataSlots = getAttributeJson(el, "data-slots")
    return mapValues(dataSlots, base64 => () => h("div", { innerHTML: atob(base64).trim() }))
}

const getHandlers = (el: HTMLElement, liveSocket: any): Record<string, (event: any) => void> => {
    const handlers = getAttributeJson(el, "data-handlers")
    const result: Record<string, (event: any) => void> = {}
    for (const handlerName in handlers) {
        const ops = handlers[handlerName]
        const snakeCaseName = `on${handlerName.charAt(0).toUpperCase() + handlerName.slice(1)}`
        result[snakeCaseName] = event => {
            const parsedOps = JSON.parse(ops)
            const replacedOps = parsedOps.map(([op, args, ...other]: [string, any, ...any[]]) => {
                if (op === "push" && !args.value) args.value = event
                return [op, args, ...other]
            })
            liveSocket.execJS(el, JSON.stringify(replacedOps))
        }
    }
    return result
}

const getProps = (el: HTMLElement, liveSocket: any): Record<string, any> => ({
    ...getAttributeJson(el, "data-props"),
    ...getHandlers(el, liveSocket),
})

export const initializeVueApp: InitializeAppFn = ({ createApp, component, props, slots, plugin, el }) => {
    const app = createApp({ render: () => h(component, props, slots) })
    app.use(plugin)
    app.mount(el)
    return app
}

export const getHooks = (components: Record<string, any>, options: Options = {}) => {
    const initializeApp = options.initializeApp || initializeVueApp
    components = normalizeComponents(components)

    const VueHook: LiveVue = {
        async mounted() {
          const el = this.el
          const componentName = el.getAttribute("data-name")
          if (!componentName) throw new Error("Component name is required")
          const component = await getComponent(components, componentName)

          const makeApp = el.getAttribute("data-ssr") === "true" ? createSSRApp : createApp

          ;(el as any)._props = reactive(getProps(el, this.liveSocket))
          ;(el as any)._slots = reactive(getSlots(el))

          const initializeContext = {
              createApp: makeApp,
              component,
              props: (el as any)._props,
              slots: (el as any)._slots,
              plugin: { install: (app: App) => app.provide(liveInjectKey, this) },
              el,
          }

          const app = initializeApp(initializeContext)
          if (!app) throw new Error("Custom initialize app function did not return an app")

          ;(el as any)._instance = app
        },
        updated() {
            Object.assign(this.el._props, getProps(this.el, this.liveSocket))
            Object.assign(this.el._slots, getSlots(this.el))
        },
        destroyed() {
            const instance = (this.el as any)._instance
            if (instance) {
                window.addEventListener("phx:page-loading-stop", () => instance.unmount(), { once: true })
            }
        },
    }

    return {
        VueHook,
    }
}
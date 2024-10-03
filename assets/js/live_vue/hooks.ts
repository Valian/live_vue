import { createApp, createSSRApp, reactive, h, type App, type Reactive, type Component } from "vue"
import { liveInjectKey } from "./use"
import { normalizeComponents, getComponent } from "./components"
import { mapValues } from "./utils"

export type Live = {
  vue: {
    props: Reactive<Record<string, any>>,
    slots: Reactive<Record<string, () => any>>,
    app: App<Element>
  }
  el: HTMLDivElement
  liveSocket: any
  pushEvent(event: string, payload?: object, onReply?: (reply: any, ref: number) => void): number
  pushEventTo(phxTarget: any, event: string, payload?: object, onReply?: (reply: any, ref: number) => void): number
  handleEvent(event: string, callback: (payload: any) => void): Function
  removeHandleEvent(callbackRef: Function): void
  upload(name: string, files: any): void
  uploadTo(phxTarget: any, name: string, files: any): void
}


/**
 * Parses the JSON object from the element's attribute and returns them as an object.
 */
const getAttributeJson = (el: HTMLElement, attributeName: string): Record<string, any> => {
    const data = el.getAttribute(attributeName)
    return data ? JSON.parse(data) : {}
}

/**
 * Parses the slots from the element's attributes and returns them as a record.
 * The slots are parsed from the "data-slots" attribute.
 * The slots are converted to a function that returns a div with the innerHTML set to the base64 decoded slot.
 */
const getSlots = (el: HTMLElement): Record<string, () => any> => {
    const dataSlots = getAttributeJson(el, "data-slots")
    return mapValues(dataSlots, base64 => () => h("div", { innerHTML: atob(base64).trim() }))
}


/**
 * Parses the event handlers from the element's attributes and returns them as a record.
 * The handlers are parsed from the "data-handlers" attribute.
 * The handlers are converted to snake case and returned as a record.
 * A special case is made for the "JS.push" event, where the event is replaced with $event.
 */
const getHandlers = (el: HTMLElement, liveSocket: any): Record<string, (event: any) => void> => {
    const handlers = getAttributeJson(el, "data-handlers")
    const result: Record<string, (event: any) => void> = {}
    for (const handlerName in handlers) {
        const ops = handlers[handlerName]
        const snakeCaseName = `on${handlerName.charAt(0).toUpperCase() + handlerName.slice(1)}`
        result[snakeCaseName] = event => {
           // a little bit of magic to replace the event with the value of the input
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


type InitializeAppArgs = {
  createApp: typeof createSSRApp | typeof createApp;
  component: Component;
  props: any;
  slots: Record<string, () => any>;
  plugin: {install: (app: App) => void};
  el: HTMLElement
}

/**
 * Initializes a Vue app with the given options and mounts it to the specified element.
 * It's a default implementation of the `initializeApp` hook option, which can be overridden.
 * If you want to override it, simply provide your own implementation of the `initializeApp` hook.
 *
 */
export const initializeVueApp = ({ createApp, component, props, slots, plugin, el }: InitializeAppArgs) => {
    const app = createApp({ render: () => h(component, props, slots) })
    app.use(plugin)
    app.mount(el)
    return app
}


type LiveVueOptions = {
  initializeApp?: typeof initializeVueApp
}

export type LiveVue = {
  [key: string]: (this: Live, ...args: any[]) => any
}

/**
 * Returns the hooks for the LiveVue app.
 * @param components - The components to use in the app.
 * @param options - The options for the LiveVue app.
 * @returns The hooks for the LiveVue app.
 */
export const getHooks = (components: Record<string, Component>, options: LiveVueOptions = {}) => {
    const initializeApp = options.initializeApp || initializeVueApp
    components = normalizeComponents(components)

    const VueHook: LiveVue = {
        async mounted() {
          const componentName = this.el.getAttribute("data-name")
          const component = await getComponent(components, componentName)

          const makeApp = this.el.getAttribute("data-ssr") === "true" ? createSSRApp : createApp

          const props = reactive(getProps(this.el, this.liveSocket))
          const slots = reactive(getSlots(this.el))

          const initializeContext = {
              createApp: makeApp,
              component,
              props,
              slots,
              plugin: { install: (app: App) => app.provide(liveInjectKey, this) },
              el: this.el,
          }

          const app = initializeApp(initializeContext)
          if (!app) throw new Error("Custom initialize app function did not return an app")

          this.vue = { props, slots, app }
        },
        updated() {
            Object.assign(this.vue.props, getProps(this.el, this.liveSocket))
            Object.assign(this.vue.slots, getSlots(this.el))
        },
        destroyed() {
            const instance = this.vue.app
            if (instance) {
                window.addEventListener("phx:page-loading-stop", () => instance.unmount(), { once: true })
            }
        },
    }

    return {
        VueHook,
    }
}
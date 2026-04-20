import { createApp, createSSRApp, reactive, type App } from "vue"
import { migrateToLiveVueApp } from "./app.js"
import type { ComponentMap, LiveVueApp, LiveVueOptions, LiveHook, Hook } from "./types.js"
import { liveInjectKey, hooksById } from "./use.js"
import { getProps, getDiff, getElementId } from "./attrs.js"
import { applyPatch } from "./jsonPatch.js"
import { registerInjector, unregisterInjector, syncSlots } from "./inject.js"

export const getVueHook = ({ resolve, setup }: LiveVueApp): Hook => ({
  async mounted() {
    const el = this.el as HTMLElement
    const componentName = el.getAttribute("data-name")
    const component = componentName ? await resolve(componentName) : null

    const props = reactive(getProps(el, this.liveSocket))
    applyPatch(props, getDiff(el, "data-streams-diff"))

    this.vue = { props, slots: reactive({}), app: null }
    const elementId = getElementId(el)
    if (elementId) hooksById.set(elementId, this as LiveHook)
    syncSlots(elementId)

    const targetId = el.getAttribute("data-inject")
    if (targetId && elementId && component) {
      const slotName = el.getAttribute("data-inject-slot") || "default"
      registerInjector(elementId, targetId, slotName, component)
      return
    }

    if (!component) return
    const makeApp = el.getAttribute("data-ssr") === "true" ? createSSRApp : createApp

    const app = setup({
      createApp: makeApp,
      component,
      props,
      slots: this.vue.slots,
      plugin: {
        install: (app: App) => {
          app.provide(liveInjectKey, this as LiveHook)
          app.config.globalProperties.$live = this as LiveHook
        },
      },
      el: this.el,
      ssr: false,
    })

    if (!app) throw new Error("Setup function did not return a Vue app!")

    this.vue.app = app
  },
  updated() {
    if (this.el.getAttribute("data-use-diff") === "true") {
      applyPatch(this.vue.props, getDiff(this.el, "data-props-diff"))
    } else {
      Object.assign(this.vue.props, getProps(this.el, this.liveSocket))
    }
    applyPatch(this.vue.props, getDiff(this.el, "data-streams-diff"))
    syncSlots(getElementId(this.el as HTMLElement))
  },
  reconnected() {
    Object.assign(this.vue.props, getProps(this.el, this.liveSocket))
    applyPatch(this.vue.props, getDiff(this.el, "data-streams-diff"))
    syncSlots(getElementId(this.el as HTMLElement))
  },
  destroyed() {
    const elementId = getElementId(this.el as HTMLElement)
    if (elementId) {
      unregisterInjector(elementId)
      hooksById.delete(elementId)
    }

    const instance = this.vue.app
    if (instance) {
      window.addEventListener("phx:page-loading-stop", () => instance.unmount(), { once: true })
    }
  },
})

/**
 * Returns the hooks for the LiveVue app.
 * @param components - The components to use in the app.
 * @param options - The options for the LiveVue app.
 * @returns The hooks for the LiveVue app.
 */
type VueHooks = { VueHook: Hook }
type getHooksAppFn = (app: LiveVueApp) => VueHooks
type getHooksComponentsOptions = { initializeApp?: LiveVueOptions["setup"] }
type getHooksComponentsFn = (components: ComponentMap, options?: getHooksComponentsOptions) => VueHooks

export const getHooks: getHooksComponentsFn | getHooksAppFn = (
  componentsOrApp: ComponentMap | LiveVueApp,
  options?: getHooksComponentsOptions
) => {
  const app = migrateToLiveVueApp(componentsOrApp, options ?? {})
  return { VueHook: getVueHook(app) }
}

import { createApp, createSSRApp, reactive, type App } from "vue"
import { migrateToLiveVueApp } from "./app.js"
import type { ComponentMap, LiveVueApp, LiveVueOptions, LiveHook, Hook } from "./types.js"
import { liveInjectKey, hooksById } from "./use.js"
import { getProps, getSlots, getDiff, getElementId, replaceSlotMap, type SlotMap } from "./attrs.js"
import { applyPatch } from "./jsonPatch.js"
import {
  injectMounted,
  injectUpdated,
  injectDestroyed,
  primeInjectionsForTarget,
  syncTargetChain,
} from "./inject.js"

export const getVueHook = ({ resolve, setup }: LiveVueApp): Hook => ({
  async mounted() {
    const el = this.el as HTMLElement
    const componentName = el.getAttribute("data-name")
    const componentPromise = Promise.resolve(componentName ? resolve(componentName) : null)

    const inject = await injectMounted(this as LiveHook, this.liveSocket, resolve)
    const props = inject?.props ?? reactive(getProps(el, this.liveSocket))
    const slots = inject?.slots ?? reactive(getSlots(el))
    if (!inject) applyPatch(props, getDiff(el, "data-streams-diff"))

    this.vue = { props, slots, app: null }
    const elementId = getElementId(el)
    if (elementId) hooksById.set(elementId, this as LiveHook)

    await primeInjectionsForTarget(elementId, this.liveSocket, resolve)

    if (inject) {
      inject.register()
      return
    }

    const component = await componentPromise
    if (!component) return
    const makeApp = el.getAttribute("data-ssr") === "true" ? createSSRApp : createApp

    const app = setup({
      createApp: makeApp,
      component,
      props,
      slots,
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
    // we're always applying streams diff, since all stream changes are sent in that attribute
    applyPatch(this.vue.props, getDiff(this.el, "data-streams-diff"))
    replaceSlotMap((this.vue.slots || {}) as SlotMap, getSlots(this.el))

    const elementId = getElementId(this.el as HTMLElement)
    if (elementId) syncTargetChain(elementId)
    injectUpdated(this.el as HTMLElement)
  },
  reconnected() {
    // after reconnect, server sends full props in data-props (not diffs)
    // read them directly instead of relying on stale data-props-diff
    // we don't delete old keys — streams live in props too and are handled by data-streams-diff
    Object.assign(this.vue.props, getProps(this.el, this.liveSocket))
    applyPatch(this.vue.props, getDiff(this.el, "data-streams-diff"))
    Object.assign(this.vue.slots ?? {}, getSlots(this.el))
  },
  destroyed() {
    injectDestroyed(this.el as HTMLElement)
    const elementId = getElementId(this.el as HTMLElement)
    if (elementId) {
      hooksById.delete(elementId)
    }

    const instance = this.vue.app
    // TODO - is there maybe a better way to cleanup the app?
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

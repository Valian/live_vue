// polyfill recommended by Vite https://vitejs.dev/config/build-options#build-modulepreload
import "vite/modulepreload-polyfill"
import { h } from "vue"
import { createLiveVue, findComponent } from "live_vue"

// Example integration with Vuetify
// not importing styles because it conflicts with tailwind, if you want vuetify don't use tailwind
// Calendar example works fine without importing styles
// https://github.com/tailwindlabs/tailwindcss/issues/465
// import "vuetify/styles"
import { createVuetify } from "vuetify"
import * as vuetifyDirectives from "vuetify/directives"
import { VCalendar } from "vuetify/labs/VCalendar"

const vuetify = createVuetify({
  vuetifyComponents: { VCalendar },
  vuetifyDirectives,
})

// Example integration wiht PrimeVue
import PrimeVue from "primevue/config"
import Aura from "@primevue/themes/aura"

export default createLiveVue({
  resolve: name => {
    // we get back a map of components with their relative paths as keys.
    // we're importing from ../../lib to allow collocating Vue files with LiveView files
    // eager: true disables lazy loading - all these components will be part of the app.js bundle
    const components = {
      ...import.meta.glob("./**/*.vue", { eager: true }),
      ...import.meta.glob("../../lib/**/*.vue"),
    }
    // finds component by name or path suffix and gives a nice error message.
    // `path/to/component/index.vue` can be found as `path/to/component` or simply `component`
    // `path/to/Component.vue` can be found as `path/to/Component` or simply `Component`
    return findComponent(components, name)
  },
  setup: ({ createApp, component, props, slots, plugin, el }) => {
    // it's a default implementation, you can easily extend it to add your own plugins, directives etc.
    const app = createApp({ render: () => h(component, props, slots) })
    app.use(plugin)
    app.use(PrimeVue, { theme: { preset: Aura } })
    app.use(vuetify)
    app.mount(el)
    return app
  },
})

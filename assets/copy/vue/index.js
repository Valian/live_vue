// polyfill recommended by Vite https://vitejs.dev/config/build-options#build-modulepreload
import "vite/modulepreload-polyfill"
import { h } from "vue"
import { createLiveVue, findComponent } from "live_vue"

export default createLiveVue({
  // name will be passed as-is in v-component of the .vue HEEX component
  resolve: name => {
    // we're importing from ../../lib to allow collocating Vue files with LiveView files
    // eager: true disables lazy loading - all these components will be part of the app.js bundle
    // more: https://vite.dev/guide/features.html#glob-import
    const components = {
      ...import.meta.glob("./**/*.vue", { eager: true }),
      ...import.meta.glob("../../lib/**/*.vue", { eager: true }),
    }

    // finds component by name or path suffix and gives a nice error message.
    // `path/to/component/index.vue` can be found as `path/to/component` or simply `component`
    // `path/to/Component.vue` can be found as `path/to/Component` or simply `Component`
    return findComponent(components, name)
  },
  // it's a default implementation of creating and mounting vue app, you can easily extend it to add your own plugins, directives etc.
  setup: ({ createApp, component, props, slots, plugin, el }) => {
    const app = createApp({ render: () => h(component, props, slots) })
    app.use(plugin)
    // add your own plugins here
    // app.use(pinia)
    app.mount(el)
    return app
  },
})

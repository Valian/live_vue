import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"

// live_vue related imports
import { getHooks, createLiveVue, findComponent } from "live_vue"
import { h } from "vue"

// polyfill recommended by Vite https://vitejs.dev/config/build-options#build-modulepreload
import "vite/modulepreload-polyfill"

// Create the liveVue app directly here
const liveVueApp = createLiveVue({
  resolve: name => {
    const components = {
      ...import.meta.glob("../vue/**/*.vue", { eager: true }),
    }

    return findComponent(components, name)
  },
  setup: ({ createApp, component, props, slots, plugin, el }) => {
    const app = createApp({ render: () => h(component, props, slots) })
    app.use(plugin)
    app.mount(el)
    return app
  },
})

let csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: getHooks(liveVueApp),
})

// connect if there are any LiveViews on the page
liveSocket.connect()
window.liveSocket = liveSocket

# Advanced Features

This guide covers advanced LiveVue features and customization options.

## Using ~V Sigil

The `~V` sigil provides an alternative to the standard LiveView DSL, allowing you to write Vue components directly in your LiveView:

```elixir
defmodule MyAppWeb.CounterLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~V"""
    <script setup lang="ts">
    import {ref} from "vue"
    const props = defineProps<{count: number}>()
    const diff = ref<number>(1)
    </script>

    <template>
      Current count: {{ props.count }}
      <input v-model="diff" type="range" min="1" max="10">
      <button
        phx-click="inc"
        :phx-value-diff="diff"
        class="button">
        Increment by {{ diff }}
      </button>
    </template>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("inc", %{"diff" => diff}, socket) do
    {:noreply, update(socket, :count, &(&1 + String.to_integer(diff)))}
  end
end
```

## Lazy Loading Components

Enable lazy loading by returning a function that returns a promise in your components configuration:

```javascript
// assets/vue/index.js
const components = {
  Counter: () => import("./Counter.vue"),
  Modal: () => import("./Modal.vue")
}

// Using Vite's glob import
const components = import.meta.glob(
  './components/*.vue',
  { eager: false, import: 'default' }
)
```

When SSR is enabled, related JS and CSS files will be automatically preloaded in HTML.

## Customizing Vue App Instance

You can customize the Vue app instance in `assets/vue/index.js`:

```javascript
import { createPinia } from "pinia"
const pinia = createPinia()

export default createLiveVue({
  setup: ({ createApp, component, props, slots, plugin, el, ssr }) => {
    const app = createApp({ render: () => h(component, props, slots) })
    app.use(plugin)
    app.use(pinia)  // Add your plugins

    if (ssr) {
      // SSR-specific initialization
    }

    app.mount(el)
    return app
  }
})
```

Available setup options:

| Property    | Description                                    |
|------------|------------------------------------------------|
| createApp   | Vue's createApp or createSSRApp function       |
| component   | The Vue component to render                    |
| props      | Props passed to the component                   |
| slots      | Slots passed to the component                   |
| plugin     | LiveVue plugin for useLiveVue functionality     |
| el         | Mount target element                           |
| ssr        | Boolean indicating SSR context                  |

## Server-Side Rendering (SSR)

LiveVue provides two SSR strategies:

### Development (ViteJS)
```elixir
# config/dev.exs
config :live_vue,
  ssr_module: LiveVue.SSR.ViteJS
```
Uses Vite's ssrLoadModule for efficient development compilation.

### Production (NodeJS)
```elixir
# config/prod.exs
config :live_vue,
  ssr_module: LiveVue.SSR.NodeJS
```
Uses elixir-nodejs for optimized production SSR with an in-memory server bundle.

### SSR Performance

Vue SSR is compiled into string concatenation for optimal performance. The SSR step:
- Only runs during "dead" renders
- Skips during live navigation
- Can be disabled per-component with `v-ssr={false}`

## Client-Side Hooks

Access Phoenix hooks from Vue components using `useLiveVue`:

```vue
<script setup>
import {useLiveVue} from "live_vue"

const hook = useLiveVue()

// Access all Phoenix hook methods
hook.pushEvent("hello", {value: "world"})
hook.handleEvent("response", (payload) => {
  console.log(payload)
})
</script>
```

## TypeScript Support

LiveVue provides full TypeScript support:

1. Use the example tsconfig.json from the example project
2. Check `example_project/assets/ts_config_example` for TypeScript versions of:
   - LiveVue entrypoint file
   - Tailwind configuration
   - Vite configuration

For app.js TypeScript support:
```javascript
// app.js
import {initApp} from './app.ts'
initApp()
```

## Next Steps

- Check out the [FAQ](faq.html) for implementation details and optimization tips
- Visit the [Deployment Guide](deployment.html) for production setup
- Join our [GitHub Discussions](https://github.com/Valian/live_vue/discussions) for questions and ideas
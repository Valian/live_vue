# Configuration

This guide covers all configuration options available in LiveVue, from basic setup to advanced customization.

## Application Configuration

LiveVue configuration is managed in your `config/config.exs` file:

```elixir
import Config

config :live_vue,
  # SSR module selection
  # For development: LiveVue.SSR.ViteJS
  # For production: LiveVue.SSR.NodeJS
  ssr_module: nil,

  # Default SSR behavior
  # Can be overridden per-component with v-ssr={true|false}
  ssr: true,

  # Vite development server URL
  # Typically http://localhost:5173 in development
  vite_host: nil,

  # SSR server bundle path (relative to priv directory)
  # Created by Vite "build-server" command
  ssr_filepath: "./vue/server.js"
```

### Environment-Specific Configuration

#### Recommended development Configuration

```elixir
# config/dev.exs
config :live_vue,
  ssr_module: LiveVue.SSR.ViteJS,
  vite_host: "http://localhost:5173",
  ssr: true
```

#### Recommended Production Configuration

```elixir
# config/prod.exs
config :live_vue,
  ssr_module: LiveVue.SSR.NodeJS,
  ssr: true

# or if you don't want to use SSR
config :live_vue,
  ssr_module: nil,
  ssr: false
```

## Vue Application Setup

Configure your Vue application in `assets/vue/index.js`. You should use createLiveVue to provide two required functions:

| Option | Type | Description |
|--------|------|-------------|
| `resolve` | `(name: string) => Component \| Promise<Component>` | Component resolution function |
| `setup` | `(context: SetupContext) => VueApp` | Vue app setup function |

Installation step provides a reasonable implementation of createLiveVue that you can use as a starting point.

### Basic Configuration

```javascript
import "vite/modulepreload-polyfill"
import { h } from "vue"
import { createLiveVue, findComponent } from "live_vue"

export default createLiveVue({
  // Component resolution - adjust this to your needs
  // Eg. You might want to import some components directly from node_modules
  // or lazy load components
  resolve: name => {
    const components = {
      ...import.meta.glob("./**/*.vue", { eager: true }),
      ...import.meta.glob("../../lib/**/*.vue", { eager: true }),
    }

    // findComponent resolves the component based on suffix.
    // Equivalent to this snippet + some error handling:
    // for (const [key, value] of Object.entries(components)) {
    //   if (key.endsWith(`${name}.vue`) || key.endsWith(`${name}/index.vue`)) {
    //     return value
    //   }
    // }
    return findComponent(components, name)
  },

  // Vue app setup
  setup: ({ createApp, component, props, slots, plugin, el }) => {
    const app = createApp({ render: () => h(component, props, slots) })
    app.use(plugin)
    app.mount(el)
    return app
  },
})
```

### SetupContext

SetupContext is an object that is passed to the setup function.

| Property | Type | Description |
|----------|------|-------------|
| `createApp` | `Function` | Vue's createApp or createSSRApp |
| `component` | `Component` | The Vue component to render |
| `props` | `object` | Props passed from LiveView |
| `slots` | `object` | Slots passed from LiveView |
| `plugin` | `Plugin` | LiveVue plugin (required) |
| `el` | `HTMLElement` | Mount target element |
| `ssr` | `boolean` | Whether this is SSR context |


### Component Resolution Options

#### Eager Loading (Default)
All components are bundled with the main application:

```javascript
const components = {
  ...import.meta.glob("./**/*.vue", { eager: true }),
}
```

#### Lazy Loading
If you want to lazy load components, you can use the `import` function:

```javascript
const components = {
  Counter: () => import("./Counter.vue"),
  Modal: () => import("./Modal.vue")
}

// Or using Vite's glob import
// useful if we colocate Vue components with LiveView components and want to put each of them into a separate chunk
// all shared components imported by top-level components will be included as well.
const components = import.meta.glob(
  "../../lib/**/*.vue",
  { eager: false, import: 'default' }
)
```

#### Custom Resolution Logic

```javascript
resolve: name => {
  // Custom component mapping and lazy loading
  const componentMap = {
    'MyCounter': () => import('./components/Counter.vue'),
    'admin/Dashboard': () => import('./admin/Dashboard.vue')
  }

  return componentMap[name]
}
```

### Vue App Customization

Add plugins, stores, and other Vue features:

```javascript
import { createPinia } from "pinia"
import { createI18n } from "vue-i18n"

export default createLiveVue({
  setup: ({ createApp, component, props, slots, plugin, el, ssr }) => {
    const app = createApp({ render: () => h(component, props, slots) })

    // LiveVue plugin (required)
    app.use(plugin)

    // Add your plugins
    const pinia = createPinia()
    app.use(pinia)

    const i18n = createI18n({
      locale: 'en',
      messages: { /* your translations */ }
    })
    app.use(i18n)

    // SSR-specific setup
    if (ssr) {
      // Server-side specific initialization
    }

    app.mount(el)
    return app
  }
})
```

## Component Organization

### Directory Structure

By default, Vue components are resolved from:
- `assets/vue/` - Main Vue components directory
- `lib/my_app_web/` - Colocated with LiveView files

### Custom Vue Root Directories

Configure component discovery paths in your LiveView module:

```elixir
# lib/my_app_web.ex
defmodule MyAppWeb do
  def html_helpers do
    quote do
      use LiveVue.Components, vue_root: [
        "./assets/vue",
        "./lib/my_app_web",
        "./lib/my_app_web/components"
      ]
    end
  end
end
```

This generates shortcut functions for your components:

```elixir
# Instead of
<.vue v-component="Counter" v-socket={@socket} />

# You can use
<.Counter v-socket={@socket} />
```

### Component Naming Conventions

Components are resolved by name or path suffix:
- `Counter.vue` → accessible as `"Counter"`
- `path/to/Component.vue` → accessible as `"path/to/Component"` or `"Component"`
- `path/to/component/index.vue` → accessible as `"path/to/component"` or `"component"`

## Server-Side Rendering (SSR)

### SSR Modules

#### ViteJS (Development)
Uses Vite's `ssrLoadModule` for efficient development compilation:

```elixir
config :live_vue,
  ssr_module: LiveVue.SSR.ViteJS,
  vite_host: "http://localhost:5173"
```

#### NodeJS (Production)
Uses elixir-nodejs with an in-memory server bundle:

```elixir
config :live_vue,
  ssr_module: LiveVue.SSR.NodeJS,
  ssr_filepath: "./vue/server.js"
```

### SSR Behavior

SSR runs only during:
- Initial page loads (dead renders)
- When enabled in config or `v-ssr={true}` is explicitly set

SSR is skipped during:
- Live navigation
- WebSocket updates
- When disabled in config or `v-ssr={false}` is set

### Per-Component SSR Control

```elixir
# Enable SSR for this component
<.vue v-component="Counter" v-ssr={true} v-socket={@socket} />

# Disable SSR for this component
<.vue v-component="Modal" v-ssr={false} v-socket={@socket} />
```

## Troubleshooting Configuration

### Common Issues

1. **Components not found**: Check `vue_root` paths in `LiveVue.Components`
2. **SSR errors**: Verify `ssr_module` and `vite_host` configuration
3. **TypeScript errors**: Ensure proper `tsconfig.json` setup
4. **Build failures**: Check Vite configuration and entry points

### Debug Configuration

Enable debug logging:

```elixir
config :logger, level: :debug

# In your component
require Logger
Logger.debug("Vue component props: #{inspect(props)}")

# on the frontend, use VueDevTools to debug
```

## Next Steps

With your configuration complete, explore:
- [Getting Started](getting_started.html) for your first component
- [Basic Usage](basic_usage.html) for common patterns
- [Advanced Features](advanced_features.html) for complex scenarios

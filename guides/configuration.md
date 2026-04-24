# Configuration

This guide covers all configuration options available in LiveVue, from basic setup to advanced customization.

## Application Configuration

LiveVue configuration is managed in your `config/config.exs` file:

```elixir
import Config

config :live_vue,
  # SSR module selection
  # For development: LiveVue.SSR.ViteJS
  # For production: LiveVue.SSR.QuickBEAM (default) or LiveVue.SSR.NodeJS
  ssr_module: nil,

  # Default SSR behavior
  # Can be overridden per-component with v-ssr={true|false}
  ssr: true,

  # Vite development server URL
  # Typically http://localhost:5173 in development
  vite_host: nil,

  # SSR server bundle path (relative to priv directory)
  # Created by the Mix assets build/deploy alias
  ssr_filepath: "./static/server.mjs",

  # Testing configuration
  # When false, we will always update full props and not send diffs
  # Useful for testing scenarios where you need complete props state
  enable_props_diff: true,

  # Raise when duplicate LiveVue component ids are registered during SSR
  # Defaults to true in dev and false elsewhere
  validate_unique_component_ids: Mix.env() == :dev,

  # Gettext backend for translating form validation errors
  # When set, Phoenix.HTML.Form errors are translated using this backend
  # Example: MyApp.Gettext
  gettext_backend: nil
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
  ssr_module: LiveVue.SSR.QuickBEAM,
  ssr: true

# or use Node.js-based SSR (requires Node.js 19+ in production):
# ssr_module: LiveVue.SSR.NodeJS

# or disable SSR entirely:
# ssr_module: nil, ssr: false
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

    // findComponent resolves by matching path segments from the end.
    // It handles both Component.vue and Component/index.vue patterns,
    // and throws helpful errors for not-found or ambiguous matches.
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
<.vue v-component="Counter" />

# You can use
<.Counter />
```

### Component Naming Conventions

Components are resolved by name or path suffix:
- `Counter.vue` → accessible as `"Counter"`
- `path/to/Component.vue` → accessible as `"path/to/Component"` or `"Component"`
- `path/to/component/index.vue` → accessible as `"path/to/component"` or `"component"`

## Server-Side Rendering (SSR)

LiveVue provides flexible SSR options that work great in both development and production environments.

### SSR Modules

LiveVue offers two SSR strategies depending on your environment:

#### ViteJS (Development)
Perfect for development with hot module replacement:

```elixir
# config/dev.exs
config :live_vue,
  ssr_module: LiveVue.SSR.ViteJS,
  vite_host: "http://localhost:5173"
```

Uses Vite's `ssrLoadModule` for efficient development compilation with instant updates.

#### NodeJS (Production)
Uses elixir-nodejs with a pre-built server bundle. Requires Node.js 19+ in production:

```elixir
# config/prod.exs
config :live_vue,
  ssr_module: LiveVue.SSR.NodeJS,
  ssr: true
```

#### QuickBEAM (Production)
Runs JavaScript inside the BEAM via an embedded [QuickBEAM](https://hex.pm/packages/quickbeam) runtime.
No external Node.js installation required. Requires [`quickbeam`](https://hex.pm/packages/quickbeam):

```elixir
# config/prod.exs
config :live_vue,
  ssr_module: LiveVue.SSR.QuickBEAM,
  ssr: true
```

See `LiveVue.SSR.QuickBEAM` module docs for setup instructions.

### SSR Configuration

Control SSR behavior globally or per-component:

```elixir
# Global SSR settings
config :live_vue,
  ssr: true,  # Enable SSR by default
  ssr_filepath: "./static/server.mjs"  # Server bundle path
```

### SSR Behavior

SSR is intelligently applied:
- **Runs during**: Initial page loads (dead renders)
- **Skips during**: Live navigation and WebSocket updates
- **Can be disabled**: Per-component with `v-ssr={false}`

> #### What are "dead renders"? {: .info}
>
> A "dead render" occurs when the page is loaded without an active WebSocket connection - this includes the initial HTTP request before LiveView connects. During this phase, SSR renders the Vue component to HTML on the server so users see content immediately.
>
> Once the WebSocket connects (making the view "live"), SSR is skipped because Vue components are already mounted and hydrated client-side. This means subsequent prop updates go directly to the mounted Vue instance without re-running SSR.

This gives you the SEO and performance benefits of SSR without the overhead during live updates.

### Per-Component SSR Control

Override global settings for specific components:

```elixir
<!-- Force SSR for this component -->
<.vue v-component="CriticalContent" v-ssr={true} />

<!-- Disable SSR for client-only widgets -->
<.vue v-component="InteractiveChart" v-ssr={false} />

<!-- Use global default -->
<.vue v-component="RegularComponent" />
```

## Testing Configuration

LiveVue provides testing-specific configuration options to help with component testing and debugging.

### enable_props_diff

By default, LiveVue optimizes performance by only sending prop changes (diffs) to the client. However, during testing, you may need access to the complete props state rather than just the incremental changes.

```elixir
# config/test.exs
config :live_vue,
  enable_props_diff: false
```

When disabled:
- LiveVue will always send full props and not send diffs
- The `props` field returned by `LiveVue.Test.get_vue/2` will contain the complete props state
- This makes it easier to write comprehensive tests that verify the full component state
- Useful for debugging component behavior and ensuring all props are correctly passed

**Note**: This option is primarily intended for testing scenarios. In production, the default behavior (sending only diffs) provides better performance.

### validate_unique_component_ids

LiveVue can raise when the same component `id` is registered more than once during SSR. This catches duplicate DOM ids early and prevents SSR injection cache collisions.

```elixir
config :live_vue,
  validate_unique_component_ids: true
```

By default this check is enabled in development and disabled elsewhere. Set it to `false` to allow duplicate ids, although duplicate DOM ids can still cause browser and hydration issues.

### SSR Performance

Vue SSR is compiled into optimized string concatenation for maximum performance. The SSR process:
- Only runs during "dead" renders (no WebSocket connection)
- Skips during live navigation for better UX
- Can be disabled per-component when not needed

### Production SSR Setup

The default production setup uses QuickBEAM, which runs JavaScript inside the BEAM — no Node.js needed at runtime.

1. **Add QuickBEAM** to your supervision tree in `application.ex`:

```elixir
children = [
  LiveVue.SSR.QuickBEAM,
  # ... other children
]
```

2. **Build server bundle** as part of your deployment:

```bash
# In your deployment script
mix assets.deploy
```

The installer configures the Mix asset alias to run both the client Vite build and the SSR build:

```elixir
"assets.deploy": [
  "phoenix_vite.npm vite build --manifest --ssrManifest --emptyOutDir true",
  "phoenix_vite.npm vite build --emptyOutDir false --ssr js/server.js --outDir ../priv/static"
]
```

The SSR bundle will be created at `priv/static/server.mjs` and loaded by QuickBEAM at startup.

### SSR Troubleshooting

**SSR not working in development?**
- Check that Vite dev server is running on the configured port
- Verify `vite_host` matches your Vite server URL

**SSR failing in production?**
- Check that `priv/static/server.mjs` exists after build
- Verify `LiveVue.SSR.QuickBEAM` is in your supervision tree
- Ensure `{:quickbeam, "~> 0.8"}` is in your dependencies

**Performance issues?**
- Disable SSR for components that don't benefit from it

## Shared Props

Shared props let you automatically inject common assigns (flash, current user, etc.) into LiveVue component tags without repeating them in every template. The same `~H` override also injects `v-socket` automatically.

This works by overriding the `~H` sigil to rewrite HEEX templates at compile time, injecting the configured props as explicit attributes. Because the props appear as regular template expressions, LiveView's change tracking works correctly.

> **History**: The runtime-based `shared_props` option was removed in v1.0.0 because it bypassed LiveView's change tracking. This compile-time approach replaces it.

### Configuration

Define shared props in `config/config.exs`:

```elixir
config :live_vue,
  shared_props: [
    :flash,
    {:current_user, :user},
    {[:current_scope, :workspace], :workspace}
  ]
```

Three formats are supported:

| Format | Example | Behavior |
|--------|---------|----------|
| `:atom` | `:flash` | Maps `assigns[:flash]` to prop `flash` |
| `{:source, :target}` | `{:current_user, :user}` | Maps `assigns[:current_user]` to prop `user` |
| `{[:path], :target}` | `{[:current_scope, :workspace], :workspace}` | Maps `get_in(assigns, [:current_scope, :workspace])` to prop `workspace` |

### Setup

In your `lib/my_app_web.ex`, override the `~H` sigil in `html_helpers`:

```elixir
defp html_helpers do
  quote do
    # ... existing imports ...
    use LiveVue

    use LiveVue.Components, vue_root: ["./assets/vue", "./lib/my_app_web"]

    # Override ~H to inject shared props and v-socket into LiveVue tags
    import Phoenix.Component, except: [sigil_H: 2]
    import LiveVue.SharedPropsView, only: [sigil_H: 2]
  end
end
```

New projects get this automatically via `mix live_vue.install`.

### How It Works

When you write:

```elixir
~H"""
<.vue v-component="MyComponent" posts={@posts} />
"""
```

With `shared_props: [:flash, {:current_user, :user}]`, the sigil rewrites the template to:

```elixir
~H"""
<.vue v-component="MyComponent" posts={@posts}
      v-socket={get_in(assigns, [:socket])}
      flash={get_in(assigns, [:flash])}
      user={get_in(assigns, [:current_user])} />
"""
```

Props explicitly passed on a tag are never duplicated. That applies both to user-configured shared props and to the builtin `v-socket` injection.

LiveVue tags are rewritten, including shortcut helpers generated by `LiveVue.Components`. If you call `LiveVue.vue/1` directly, pass `v-socket` explicitly there.


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
- [Getting Started](getting_started.md) for your first component
- [Basic Usage](basic_usage.md) for common patterns

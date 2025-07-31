# Installation

LiveVue replaces `esbuild` with [Vite](https://vitejs.dev/) for both client side code and SSR to achieve an amazing development experience.

## Why Vite?

- Vite provides a best-in-class Hot-Reload functionality and offers [many benefits](https://vitejs.dev/guide/why#why-vite)
- `esbuild` package doesn't support plugins, so we would need to setup a custom build process anyway
- In production, we'll use [elixir-nodejs](https://github.com/revelrylabs/elixir-nodejs) for SSR

If you don't need SSR, you can easily disable it with one line of configuration.

## Prerequisites

- Node.js installed (version 19 or later recommended)
- Phoenix 1.7+ project
- Elixir 1.13+

## Setup Steps

> #### Installation with Igniter {: .tip}
>
> I'm aware that installation process takes a moment to complete, but it's worth it! 🫣
> There's also ongoing work to create an igniter installer for LiveVue, should be ready in the next version 🤞

1. Add LiveVue to your dependencies:

```elixir
def deps do
  [
    {:live_vue, "~> 0.7"}
  ]
end
```

2. Configure environments:

```elixir
# in config/dev.exs
config :live_vue,
  vite_host: "http://localhost:5173",
  ssr_module: LiveVue.SSR.ViteJS,
  # if you want to disable SSR by default, set this to false
  ssr: true

# in config/prod.exs
config :live_vue,
  ssr_module: LiveVue.SSR.NodeJS,
  ssr: true
```

3. Add LiveVue to your `html_helpers` in `lib/my_app_web.ex`:

```elixir
defp html_helpers do
  quote do
    # ... existing code ...

    # Add support for Vue components
    use LiveVue

    # Generate component for each vue file, so you can use <.ComponentName> syntax
    # instead of <.vue v-component="ComponentName">
    use LiveVue.Components, vue_root: ["./assets/vue", "./lib/my_app_web"]
  end
end
```

4. Run the setup command to generate required files:

```bash
mix deps.get
mix live_vue.setup
cd assets && npm install
```

The `live_vue.setup` command will create:
- `package.json` with required dependencies
- Vite, TypeScript, and PostCSS configs
- Server entrypoint for SSR
- Vue entrypoint files

5. Update your JavaScript configuration:

```javascript
// app.js
import topbar from "topbar" // instead of ../vendor/topbar
import {getHooks} from "live_vue"
import liveVueApp from "../vue"

// remember to import your css here
import "../css/app.css"

let liveSocket = new LiveSocket("/live", Socket, {
    // ... existing options ...
    hooks: getHooks(liveVueApp),
})
```

6. Configure Tailwind to include Vue files:

```javascript
// tailwind.config.js
module.exports = {
    content: [
        // ... existing patterns
        "./vue/**/*.vue",
        "../lib/**/*.vue",
    ],
}
```

7. Update root.html.heex for Vite:

```heex
<LiveVue.Reload.vite_assets assets={["/js/app.js", "/css/app.css"]}>
  <link phx-track-static rel="stylesheet" href="/assets/app.css" />
  <script type="module" phx-track-static type="text/javascript" src="/assets/app.js">
  </script>
</LiveVue.Reload.vite_assets>
```

8. Remove esbuild and tailwind packages from your dependencies in `mix.exs`:

```elixir
defp deps do
  [
    # Remove these lines:
    # {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
    # {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},

    # ... other dependencies ...
  ]
end
```

9. Update your `mix.exs` aliases:

```elixir
defp aliases do
  [
    setup: ["deps.get", "assets.setup", "assets.build"],
    "assets.setup": ["cmd --cd assets npm install"],
    "assets.build": [
      "cmd --cd assets npm run build",
      "cmd --cd assets npm run build-server"
    ],
    "assets.deploy": [
      "cmd --cd assets npm run build",
      "cmd --cd assets npm run build-server",
      "phx.digest"
    ]
  ]
end
```

10. Remove esbuild and tailwind config from `config/config.exs`

11. Configure watchers in `config/dev.exs`:

```elixir
config :my_app, MyAppWeb.Endpoint,
  watchers: [
    npm: ["--silent", "run", "dev", cd: Path.expand("../assets", __DIR__)]
  ]
```

12. Setup SSR for production in `application.ex`:

```elixir
children = [
  {NodeJS.Supervisor, [path: LiveVue.SSR.NodeJS.server_path(), pool_size: 4]},
  # ... other children
]
```

13. Confirm everything is working by rendering an example Vue component in one of your LiveViews:

```elixir
~H"""
<.vue
  count={@count}
  v-component="Counter"
  v-socket={@socket}
  v-on:inc={JS.push("inc")}
/>
"""
```

14. (Optional) Enable [stateful hot reload](https://twitter.com/jskalc/status/1788308446007132509) for LiveViews:

This provides a superior development experience by preserving the LiveView's state (e.g., form data, temporary assigns) while Vite instantly updates the Vue component's code on the client. You get the best of both worlds: state persistence from the server and immediate UI updates from the client.

```elixir
# config/dev.exs
config :my_app, MyAppWeb.Endpoint,
  live_reload: [
    notify: [
      live_view: [
        ~r"lib/my_app_web/core_components.ex$",
        ~r"lib/my_app_web/(live|components)/.*(ex|heex)$"
      ]
    ],
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/my_app_web/controllers/.*(ex|heex)$"
    ]
  ]
```

## Manually Adjusting package.json

If you need to set up your `package.json` manually instead of using `mix live_vue.setup`, follow these steps:

1. Install the required packages:

```bash
cd assets

# vite
npm install -D vite @vitejs/plugin-vue

# tailwind
npm install -D tailwindcss autoprefixer postcss @tailwindcss/forms

# typescript
npm install -D typescript vue-tsc

# runtime dependencies
npm install --save vue topbar ../deps/live_vue ../deps/phoenix ../deps/phoenix_html ../deps/phoenix_live_view

# remove topbar from vendor, since we'll use it from node_modules
rm vendor/topbar.js
```

2. Add these scripts to your `package.json`:

```json
{
    "private": true,
    "type": "module",
    "scripts": {
        "dev": "vite --host -l warn",
        "build": "vue-tsc && vite build",
        "build-server": "vue-tsc && vite build --ssr js/server.js --out-dir ../priv/vue --minify esbuild --ssrManifest && echo '{\"type\": \"module\" } ' > ../priv/vue/package.json"
    }
}
```

## Troubleshooting

### TypeScript Compatibility Issues

There's a [known bug](https://github.com/vuejs/language-tools/issues/5018) where recent versions of TypeScript are not compatible with the latest version of `vue-tsc`. If you encounter an error like:

```bash
npm install typescript@5.5.4 vue-tsc@2.10.0
```

You'll need to downgrade TypeScript and vue-tsc to specific versions:

```bash
npm install typescript@5.5.4 vue-tsc@2.10.0
```

This issue has been documented in [LiveVue issue #43](https://github.com/Valian/live_vue/issues/43#issuecomment-2501152160).

### Protocol.UndefinedError with Custom Structs

If you encounter a `Protocol.UndefinedError` mentioning `LiveVue.Encoder` when passing custom structs as props, you need to implement the encoder protocol:

```elixir
# Add this to your struct definitions
defmodule User do
  @derive LiveVue.Encoder
  defstruct [:name, :email, :age]
end
```

This is a safety feature to prevent accidental exposure of sensitive data. For more details, see [Component Reference](component_reference.md#custom-structs-with-livevue-encoder).

## Next Steps

Now that you have LiveVue installed, check out our [Getting Started Guide](getting_started.md) to create your first Vue component!
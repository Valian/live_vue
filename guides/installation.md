# Installation

LiveVue replaces `esbuild` with [Vite](https://vitejs.dev/) for both client side code and SSR to achieve an amazing development experience.

## Why Vite?

- Vite provides a best-in-class Hot-Reload functionality and offers [many benefits](https://vitejs.dev/guide/why#why-vite)
- `esbuild` package doesn't support plugins, so we would need to setup it anyway
- In production, we'll use [elixir-nodejs](https://github.com/revelrylabs/elixir-nodejs) for SSR

## Prerequisites

- Node.js installed (version 19 or later recommended)
- Phoenix 1.7+ project
- Elixir 1.13+

## Setup Steps

1. Add LiveVue to your dependencies:

```elixir
def deps do
  [
    {:live_vue, "~> 0.5"}
  ]
end
```

2. Configure environments:

```elixir
# in config/dev.exs
config :live_vue,
  vite_host: "http://localhost:5173",
  ssr_module: LiveVue.SSR.ViteJS

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
    use LiveVue
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

5. Update your JavaScript configuration:

```javascript
// app.js
import {getHooks} from "live_vue"
import liveVueApp from "../vue"

let liveSocket = new LiveSocket("/live", Socket, {
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

8. Configure watchers in `config/dev.exs`:

```elixir
config :my_app, MyAppWeb.Endpoint,
  watchers: [
    npm: ["--silent", "run", "dev", cd: Path.expand("../assets", __DIR__)]
  ]
```

9. Setup SSR for production in `application.ex`:

```elixir
children = [
  {NodeJS.Supervisor, [path: LiveVue.SSR.NodeJS.server_path(), pool_size: 4]},
  # ... other children
]
```

10. (Optional) Enable [stateful hot reload](https://twitter.com/jskalc/status/1788308446007132509):

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

## Troubleshooting

### TypeScript Compatibility

If you encounter TypeScript errors, you may need to downgrade typescript and vue-tsc:

```bash
npm install typescript@5.5.4 vue-tsc@2.10.0
```

## Next Steps

See our [Getting Started Guide](getting_started.html) for creating your first Vue component!
# Installation

LiveVue replaces `esbuild` with [Vite](https://vitejs.dev/) for both client side code and SSR to achieve an amazing development experience. Why?

-   Vite provides a best-in-class Hot-Reload functionality and offers [many benefits](https://vitejs.dev/guide/why#why-vite) not present in esbuild
-   `esbuild` package doesn't support plugins, so we would need to setup it anyway

In production, we'll use [elixir-nodejs](https://github.com/revelrylabs/elixir-nodejs) for SSR. If you don't need SSR, you can disable it with one line of code. TypeScript will be supported as well.

## Steps

0. Please install `node` 😉

1. Add `live_vue` to your list of dependencies of your Phoenix app in `mix.exs` and run `mix deps.get`

```elixir
defp deps do
  [
    {:live_vue, "~> 0.4"}
  ]
end
```

2. Add config entry to your `config/dev.exs` file

```elixir
config :live_vue,
  vite_host: "http://localhost:5173",
  ssr_module: LiveVue.SSR.ViteJS,
  # if you want to disable SSR by default, make it false
  ssr: true
```

3. Add config entry to your `config/prod.exs` file

```elixir
config :live_vue,
  ssr_module: LiveVue.SSR.NodeJS,
  ssr: true
```

4. Add LiveVue to your `html_helpers` in `lib/my_app_web.ex`

```elixir
defp html_helpers do
  quote do
    # ...
    # Add support to Vue components
    use LiveVue

    # Generate component for each vue file, so you can omit v-component="name".
    # You can configure path to your components by using optional :vue_root param
    use LiveVue.Components, vue_root: ["./assets/vue", "./lib/my_app_web"]
  end
end
```

5. LiveVue comes with a handy command to setup all the required files. It won't alter any files you already have in your project, you need to adjust them on your own by looking at the provided sources. Additional instructions how to adjust `package.json` can be found at the end of this page.

It will create:

-   `package.json`
-   vite, typescript and postcss configs
-   server entrypoint
-   vue components root

```bash
mix deps.get
mix live_vue.setup
cd assets && npm install
```

Now we just have to adjust `js/app.js` hooks and tailwind config to include `vue` files:

```js
// app.js
import topbar from "topbar" // instead of ../vendor/topbar
import {getHooks} from "live_vue"
import components from "../vue"
import "../css/app.css"

let liveSocket = new LiveSocket("/live", Socket, {
    // ...
    hooks: getHooks(components),
})
```

```js
// tailwind.config.js

module.exports = {
    content: [
        // ...
        // include Vue files
        "./vue/**/*.vue",
        "../lib/**/*.vue",
    ],
}
```

6. Let's update root.html.heex to use Vite files in development. There's a handy wrapper for it.

```html
<!-- Wrap existing CSS and JS in LiveVue.Reload.vite_assets component,
pass paths to original files in assets -->

<LiveVue.Reload.vite_assets assets={["/js/app.js", "/css/app.css"]}>
  <link phx-track-static rel="stylesheet" href="/assets/app.css" />
  <script type="module" phx-track-static type="text/javascript" src="/assets/app.js">
  </script>
</LiveVue.Reload.vite_assets>
```

7. Update `mix.exs` aliases and get rid of `tailwind` and `esbuild` packages

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

defp deps do
  [
    # remove these lines, we don't need esbuild or tailwind here anymore
    # {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
    # {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
  ]
end
```

8. Remove esbuild and tailwind config from `config/config.exs`

9. Update watchers in `config/dev.exs` to look like this

```elixir
config :my_app, MyAppWeb.Endpoint,
  # ...
  watchers: [
    npm: ["run", "dev", cd: Path.expand("../assets", __DIR__)]
  ]

```

10. To make SSR working with `LiveVue.SSR.NodeJS` (recommended for production), you have to add this entry to your `application.ex` supervision tree:

```elixir
children = [
  {NodeJS.Supervisor, [path: LiveVue.SSR.NodeJS.server_path(), pool_size: 4]},
  # ...
]
```

11. Confirm everything is working by rendering an example Vue component anywhere in your LiveViews:

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

12. (Optional) enable [stateful hot reload](https://twitter.com/jskalc/status/1788308446007132509) of phoenix LiveViews - it allows for stateful reload across the whole stack 🤯. Just adjust your `dev.exs` to loook like this - add `notify` section and remove `live|components` from patterns.

```elixir
# Watch static and templates for browser reloading.
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

Voila! Easy, isn't it? 😉

## Adjust your own package.json

Install these packages

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

and add these scripts used by watcher and `mix assets.build` command

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

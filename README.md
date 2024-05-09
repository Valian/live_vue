<div align="center">

# LiveVue

[![GitHub](https://img.shields.io/github/stars/Valian/live_vue?style=social)](https://github.com/Valian/live_vue)
[![Hex.pm](https://img.shields.io/hexpm/v/live_vue.svg)](https://hex.pm/packages/live_vue)

Vue inside Phoenix LiveView with seamless end-to-end reactivity

![logo](https://github.com/Valian/live_vue/blob/master/logo.png?raw=true)

[Features](#features) •
[Resources](#resources) •
[Demo](#demo) •
[Installation](#installation) •
[Usage](#usage) •
[Deployment](#deployment)

</div>

## Features

-   ⚡ **End-To-End Reactivity** with LiveView
-   🔋 **Server-Side Rendered** (SSR) Vue
-   🪄 **Sigil** as an [Alternative LiveView DSL](#livevue-as-an-alternative-liveview-dsl)
-   🦄 **Tailwind** Support
-   💀 **Dead View** Support
-   🦥 **Slot Interoperability**

## Resources

-   [HexDocs](https://hexdocs.pm/live_vue)
-   [HexPackage](https://hex.pm/packages/live_vue)
-   [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view)

## Demo

TODO

## Installation

### Core

LiveVue uses Vite for an amazing development experience, for both client side and SSR.

In production, we'll setup it's recommented to use nodejs hex package for SSR.

1. Add `live_vue` to your list of dependencies of your Phoenix app in `mix.exs`:

```elixir
defp deps do
  [
    {:live_vue, "~> 0.1"}
  ]
end
```

and run `mix deps.get`

2. Add config entry to your `config/dev.exs` file

```elixir
config :live_vue,
  vite_host: "http://localhost:5173",
  ssr_module: LiveVue.SSR.ViteJS
```

3. Add LiveVue to your `html_helpers` in `lib/my_app_web.ex`

```elixir
defp html_helpers do
  quote do
    # ...
    # Add support to Vue components
    use LiveVue
    use LiveVue.Components
  end
end
```

4. Setup JS files. We switch esbuild to vite and add SSR entrypoint. We also add postcss config to handle tailwind and tsconfig to support TypeScript.

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

Next, let's copy SSR entrypoint, vite config and typescript config from `live_vue`. If you have any of these files, please adjust accordingly.

```bash
# this should be only dir we need
mkdir vue

for SOURCE in $(find ../deps/live_vue/assets/copy -type f); do
  DEST=${SOURCE#../deps/live_vue/assets/copy/}

  if [ -e "$DEST" ]; then
    echo "SKIPPED $SOURCE -> $DEST. Please update manually"
  else
    echo "COPIED $SOURCE -> $DEST"
    cp $SOURCE $DEST
  fi
done
```

Now we just have to adjust app.js hooks and tailwind config to include `vue` files:

```js
// app.js
import topbar from "topbar" // instead of ../vendor/topbar
// ...
import {getHooks} from "live_vue"
import components from "../vue"

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
        "./vue/**/*.vue", // include Vue files
    ],
}
```

and lastly let's add helpful scripts to package.json

```json
// package.json
{
    "private": true,
    "type": "module",
    "scripts": {
        "dev": "vite --host -l warn",
        "build": "vue-tsc && vite build",
        "build-server": "vue-tsc && vite build --ssr js/server.js --out-dir ../priv/vue --minify esbuild && mv ../priv/vue/server.js ../priv/vue/server.mjs"
    },
    "devDependencies": {
        // ...
    },
    "dependencies": {
        // ...
    }
}
```

5. Let's update root.html.heex to use Vite files in development. There's a handy wrapper for it.

```html
<!-- Wrap existing CSS and JS in LiveVue.Reload.vite_assets component,
pass paths to original files in assets -->

<LiveVue.Reload.vite_assets assets={["/js/app.js", "/css/app.css"]}>
  <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
  <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
  </script>
</LiveVue.Reload.vite_assets>
```

6. Update `mix.exs` aliases and get rid of `tailwind` and `esbuild` packages

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
    # remove these lines
    # {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
    # {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
  ]
end
```

7. Remove esbuild and tailwind config from `config/config.exs`

8. Update watchers in `config/dev.exs` to look like this

```elixir
config :my_app, MyAppWeb.Endpoint,
  # ...
  watchers: [
    npm: ["run", "dev", cd: Path.expand("../assets", __DIR__)]
  ]

```

Voila! Easy, isn't it? 😉

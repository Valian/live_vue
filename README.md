<div align="center">

# LiveVue

[![GitHub](https://img.shields.io/github/stars/Valian/live_vue?style=social)](https://github.com/Valian/live_vue)
[![Hex.pm](https://img.shields.io/hexpm/v/live_vue.svg)](https://hex.pm/packages/live_vue)

Vue inside Phoenix LiveView with seamless end-to-end reactivity.

![logo](https://github.com/Valian/live_vue/blob/master/logo.png?raw=true)

[Features](#features) •
[Resources](#resources) •
[Demo](#demo) •
[Installation](#installation) •
[Usage](#usage) •
[Deployment](#deployment)

</div>

## Resources

-   [HexDocs](https://hexdocs.pm/live_vue)
-   [HexPackage](https://hex.pm/packages/live_vue)
-   [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view)

## Features

-   ⚡ **End-To-End Reactivity** with LiveView
-   🔋 **Server-Side Rendered** (SSR) Vue
-   🪄 **Sigil** as an [Alternative LiveView DSL](#livevue-as-an-alternative-liveview-dsl)
-   🦄 **Tailwind** Support
-   💀 **Dead View** Support
-   🦥 **Slot Interoperability**
-   🚀 **Amazing DX** with Vite

## Example

You can use Vue components in the same way as you'd use functional LiveView components. You can even handle Vue events with `JS` hooks! All the `phx-click`, `phx-change` attributes works as well.

```vue
<script setup lang="ts">
import {ref} from "vue"
const props = defineProps<{count: number}>()
const emit = defineEmits<{inc: [{value: number}]}>()
const diff = ref<string>("1")
</script>

<template>
    Current count
    <div class="text-2xl text-bold">{{ props.count }}</div>
    <label class="block mt-8">Diff: </label>
    <input v-model="diff" class="mt-4" type="range" min="1" max="10" />

    <button @click="emit('inc', {value: parseInt(diff)})" class="mt-4 bg-black text-white rounded p-2 block">
        Increase counter by {{ diff }}
    </button>
</template>
```

```elixir
defmodule LiveVueExamplesWeb.LiveCounter do
  use LiveVueExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <.vue
      count={@count}
      v-component="Counter"
      v-socket={@socket}
      v-on:inc={JS.push("inc")}
    />
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :counter, 0)}
  end

  def handle_event("inc", %{"value" => diff}, socket) do
    {:noreply, update(socket, :count, &(&1 + diff))}
  end
end

```

## Relation to LiveSvelte

This project is heavily inspired by ✨ [LiveSvelte](https://github.com/woutdp/live_svelte) ✨. Both projects try to solve the same problem. LiveVue was started as a fork fo LiveSvelte with adjusted ESbuild settings, and evolved to use Vite and a slightly different syntax. I strongly believe more options are always better, and since I love Vue and it's ecosystem I've decided to give it a go 😉

## Demo

TODO

## Why?

Phoenix Live View makes it possible to create rich, interactive web apps without writing JS. But once you'll need to do anything even slightly complex on the client-side, you'll end up writing lots of imperative, hard-to-maintain hooks. LiveVue allows to create hybrid apps, where part of the session state is on the server and part on the client.

### Reasons why you'd like to use LiveVue

-   Your hooks are starting to look like jQuery 😅
-   You have a complex local state
-   You'd like to use a massive Vue ecosystem
-   You want transitions, graphs etc.
-   You simply like Vue 😉

## Installation

LiveVue replaces `esbuild` with [Vite](https://vitejs.dev/) for both client side code and SSR to achieve an amazing development experience. In production, we'll use [elixir-nodejs](https://github.com/revelrylabs/elixir-nodejs) for SSR. If you don't need SSR, you can disable it with one line of code. TypeScript will be supported as well.

0. Please install `node` 😉

1. Add `live_vue` to your list of dependencies of your Phoenix app in `mix.exs` and run `mix deps.get`

```elixir
defp deps do
  [
    {:live_vue, "~> 0.1"}
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
    # Right now works only for top-level files inside `assets/vue`.
    # You can configure path to your components by using optional :vue_root param
    use LiveVue.Components, vue_root: "./assets/vue/*.vue"
  end
end
```

5. Setup JS files. We switch esbuild to vite and add SSR entrypoint. We also add postcss config to handle tailwind and tsconfig to support TypeScript.

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

Next, let's copy SSR entrypoint, vite config and typescript config from `live_vue`. If you have any of these files, they'll be skipped so you could update them on your own.

```bash
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

6. Let's update root.html.heex to use Vite files in development. There's a handy wrapper for it.

```html
<!-- Wrap existing CSS and JS in LiveVue.Reload.vite_assets component,
pass paths to original files in assets -->

<LiveVue.Reload.vite_assets assets={["/js/app.js", "/css/app.css"]}>
  <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
  <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
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

Voila! Easy, isn't it? 😉

## Usage

Vue components need to go into the assets/vue directory.

### Basic usage

To render vue component from HEEX, you have to use `<.vue>` function with these attributes:

-   `v-component`: Specify the Vue component. The name must match key defined in `components` passed to `getHooks` function in `app.js`. By default, it's a path from `assets/vue` without extension. Example: `Counter` -> `assets/vue/Counter.vue`, `helpers/modal` -> `assets/vue/helpers/modal.vue`.
-   `v-socket`: LiveVue socket. Used to determine if SSR is needed or not, so it should be always included in LiveViews.
-   `v-ssr`: Specify if SSR should be used or not. Defaults to `Application.compile_env(:live_vue, :ssr, true)`. To make it work, `:live_vue, :ssr_module` also has to be specified.
-   `v-on:event={@handler}`: Handle component event by invoking JS hook. @handler has to come from `JS` module. Example: `v-on:toggle={JS.toggle()}`
-   `prop={@value}`: All other attributes will be passed to vue component as props. Values have to be serializable to JSON, so structures have to implement `Jason.Encoder` protocol.

### Shortcut

Instead of writing `<.vue v-component="Counter">` you can use shortcut `<.Counter>`. Function names are generated based on content of `assets/vue` directory.

### Passing props

You pass props in the same way as with functional components in Elixir. All 3 examples does exactly the same.

```elixir
<.vue
  count={@count}
  name={@name}
  v-component="Counter"
  v-socket={@socket}
/>

<.vue
  v-component="Counter"
  v-socket={@socket}
  {%{count: @count, name: @name}}
/>

<.Counter
  count={@count}
  name={@name}
  v-socket={@socket}
/>
```

### Handling events

All regular phoenix hooks like `phx-click`, `phx-submit` work as expected.
To keep components DRY you can define vue handlers using `v-on:eventname={JS.handler()}` syntax.
All attributes starting with `v-on:` are attached as emit handlers to Vue components and executed in the same way as Phoenix does it.

`JS.push("someName")` is a special case - if JS.push defines no value, it will be replaced by the emit payload.

```elixir
<.vue v-on:submit={JS.push("submit")} v-component="SomeForm" v-socket={@socket} />
<.vue
  v-on:shoot={JS.push("shoot")}
  v-on:close={JS.hide()}
  v-component="SomeGame"
  v-socket={@socket}
/>
```

### Passing slots

You can even pass slots to the vue component! They're passed to vue as raw HTML, so hooks in the slots won't work. Each slot is wrapped in a div due to technical limitations.

-   Default slot can be passed as `:inner_block` and rendered inside Vue components as `<slot />`.
-   Named slots can be passed by using `<:slot_name>Content</:slot_name>` syntax are rendered using `<slot name="slot_name" />` syntax.
-   Slots will be kept in sync, as expected.

An example:

```elixir
<.Card title="The coldest sunset" v-socket={@socket}>
  <p>This is card content passed from phoenix!</p>
  <p>Even icons are working! <.icon name="hero-information-circle-mini" /></p>
  <:footer>And this is a footer from phoenix</:footer>
</.Card>
```

```vue
<template>
    <slot></slot>
    Footer:
    <slot name="footer"></slot>
</template>
```

### Dead views vs Live views

You can use `<.vue>` components in dead views. Of course, there will be no updates on assign changes, since there is no websocket connection established to support it.

v-socket={@socket} is not required in dead views.

### Note on SSR

Vue SSR is compiled down into string concatenation, so it's quite fast 😉

In development it's recommended to use `config :live_vue, ssr_module: LiveVue.SSR.ViteJS`. It does HTTP call to vite `/ssr_render` endpoint added by LiveVue plugin, which in turn uses vite [ssrLoadModule](https://vitejs.dev/guide/ssr) for efficient compilation.

In production it's recommended to use `config :live_vue, ssr_module: LiveVue.SSR.NodeJS` which uses `NodeJS` package directly talking with a JS process with a in-memory server bundle. By default, SSR bundle is saved to `priv/vue/server.mjs`. `mjs` extension is necessary so NodeJS correctly imports that file as `ESM module`.

### Handling custom Phoenix events client side

TODO

### Using ~V sigil to inline Vue components

TODO

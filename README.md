[![Hex.pm](https://img.shields.io/hexpm/v/live_vue.svg)](https://hex.pm/packages/live_vue)
[![Hexdocs.pm](https://img.shields.io/badge/docs-hexdocs.pm-purple)](https://hexdocs.pm/live_vue)
[![GitHub](https://img.shields.io/github/stars/Valian/live_vue?style=social)](https://github.com/Valian/live_vue)

# LiveVue

Vue inside Phoenix LiveView with seamless end-to-end reactivity.

![logo](https://github.com/Valian/live_vue/blob/main/logo.png?raw=true)

## Resources

-   [HexDocs](https://hexdocs.pm/live_vue)
-   [HexPackage](https://hex.pm/packages/live_vue)
-   [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view)

## Table of content

-   [Features](#features)
-   [Resources](#resources)
-   [Example](#example)
-   [Installation](#installation)
-   [Usage](#usage)
-   [Deployment](#deployment)
-   [FAQ](#faq)

## Features

-   ⚡ **End-To-End Reactivity** with LiveView
-   🔋 **Server-Side Rendered** (SSR) Vue
-   🪄 **Sigil** as an [Alternative LiveView DSL](#livevue-as-an-alternative-liveview-dsl)
-   🦄 **Tailwind** Support
-   💀 **Dead View** Support
-   🦥 **Slot Interoperability**
-   🚀 **Amazing DX** with Vite

## Example

After installation, you can use Vue components in the same way as you'd use functional LiveView components. You can even handle Vue events with `JS` hooks! All the `phx-click`, `phx-change` attributes works inside Vue components as well.

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
    <input v-model="diff" class="my-4" type="range" min="1" max="10" />

    <button
        @click="emit('inc', {value: parseInt(diff)})"
        class="bg-black text-white rounded p-2"
    >
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

You can read more about differences between Vue and Svelte [in FAQ](#differences-from-livesvelte).

## Why?

Phoenix Live View makes it possible to create rich, interactive web apps without writing JS.

But once you'll need to do anything even slightly complex on the client-side, you'll end up writing lots of imperative, hard-to-maintain hooks.

LiveVue allows to create hybrid apps, where part of the session state is on the server and part on the client.

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
    {:live_vue, "~> 0.2"}
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
    # Right now works only for top-level files.
    # You can configure path to your components by using optional :vue_root param
    use LiveVue.Components, vue_root: ["./assets/vue", "./lib/my_app_web"]
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
        "./vue/**/*.vue",
        "../lib/**/*.vue", // include Vue files
    ],
}
```

and lastly let's add dev and build scripts to package.json

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

## Usage

By default, vue components should be placed either inside `assets/vue` directory or colocated with your Elixir files. You can configure that behaviour by changing `assets/vue/index.js` and `use LiveVue.Components, vue_root: ["your/vue/dir"]`.

### Basic usage

To render vue component from HEEX, you have to use `<.vue>` function with these attributes:

| Attribute             | Example                                                   | Required        | Description                                                                                                                                                                                                            |
| --------------------- | --------------------------------------------------------- | --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| v-component           | `v-component="Counter"`<br>`v-component="helpers/modal"`  | yes             | Name of the component to render. Must match key defined in `components` passed to `getHooks`. By default you can use both filename or a full file path without extension, relative to `assets/vue` or `lib/my_app_web` |
| v-socket              | `v-socket={@socket}`                                      | Yes in LiveView | Used to determine if SSR is needed. Should be always included in LiveViews                                                                                                                                             |
| v-ssr                 | `v-ssr={true}`                                            | no              | Defaults to `Application.get_env(:live_vue, :ssr, true)`                                                                                                                                                               |
| v-on:event={@handler} | `v-on:close={JS.toggle()}`                                | no              | Handle component event by invoking JS hook. @handler has to come from `JS` module. See Usage section for more.                                                                                                         |
| prop={@value}         | `name="liveVue"`<br>`count={@count}`<br>`{%{count: 123}}` | no              | All other attributes will be passed to vue component as props. Values have to be serializable to JSON, so structures have to implement `Jason.Encoder` protocol.                                                       |

### Shortcut

Instead of writing `<.vue v-component="Counter">` you can use shortcut `<.Counter>`. Function names are generated based on filenames of found `.vue` files, so `assets/vue/helpers/nested/Modal.vue` will generate helper `<.Modal>`. If there are multiple `.vue` files with equal names, use `<.vue v-component="path/to/file">`

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

In production it's recommended to use `config :live_vue, ssr_module: LiveVue.SSR.NodeJS` which uses `NodeJS` package directly talking with a JS process with a in-memory server bundle. By default, SSR bundle is saved to `priv/vue/server.js`.

### Handling custom Phoenix events client side

You can use function `useLiveVue` to access root phoenix element where Vue component was routed.

API of that object is described in [Phoenix docs](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook).

Example

```vue
<script>
import {useLiveVue} from "live_vue"

const hook = useLiveVue()

hook.pushEvent("hello", {value: "from Vue"})
</script>
```

### Using ~V sigil to inline Vue components

We can go one step further and use LiveVue as an alternative to the standard LiveView DSL. This idea is taken from `LiveSvelte`.

Take a look at the following example:

```elixir
defmodule ExampleWeb.LiveSigil do
  use ExampleWeb, :live_view

  def render(assigns) do
    ~V"""
    <script setup lang="ts">
    import {ref} from "vue"
    const props = defineProps<{count: number}>()
    const diff = ref<number>(1)
    </script>

    <template>
      Current count
      <div class="text-2xl text-bold">{{ props.count }}</div>
      <label class="block mt-8">Diff: </label>
      <input v-model="diff" class="mt-4" type="range" min="1" max="10">

      <button
        phx-click="inc"
        :phx-value-diff="diff"
        class="mt-4 bg-black text-white rounded p-2 block">
        Increase counter {{ diff }}
      </button>
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

Use the `~V` sigil instead of `~H` and your LiveView will be Vue instead of an HEEx template.

## LiveVue Development

### Local Setup

#### Example Project

You can use `/example_project` as a way to test `live_vue` locally.

#### Custom Project

You can also use your own project.

Clone `live_vue` to the parent directory of the project you want to test it in.

Inside `mix.exs`

```elixir
{:live_vue, path: "../live_vue"},
```

Inside `assets/package.json`

```javascript
"live_vue": "file:../../live_vue",
```

### Building Static Files

Make the changes in `/assets/js` and run:

```bash
mix assets.build
```

Or run the watcher:

```bash
mix assets.build --watch
```

### Releasing

Release is done with `expublish` package.

-   Write version changelog in untracked `RELEASE.md` file
-   Update version in `README.md`

Run

```bash
mix assets.build
git add README.md priv
git commit -m "README version bump"

# to ensure everything works fine
mix expublish.minor --dry-run --allow-untracked --branch=main

# to publish everything
mix expublish.minor --allow-untracked --branch=main
```

## Deployment

Deploying a LiveVue app is the same as deploying a regular Phoenix app, except that you will need to ensure that `nodejs` (version 19 or later) is installed in your production environment.

The below guide shows how to deploy a LiveVue app to [Fly.io](https://fly.io/), but similar steps can be taken to deploy to other hosting providers.
You can find more information on how to deploy a Phoenix app [here](https://hexdocs.pm/phoenix/deployment.html).

### Deploying on Fly.io

The following steps are needed to deploy to Fly.io. This guide assumes that you'll be using Fly Postgres as your database. Further guidance on how to deploy to Fly.io can be found [here](https://fly.io/docs/elixir/getting-started/).

1. Generate a `Dockerfile`:

```bash
mix phx.gen.release --docker
```

2. Modify the generated `Dockerfile` to install `curl`, which is used to install `nodejs` (version 19 or greater), and also add a step to install our `npm` dependencies:

```diff
# ./Dockerfile

...

# install build dependencies
- RUN apt-get update -y && apt-get install -y build-essential git \
+ RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

+ # install nodejs for build stage
+ RUN curl -fsSL https://deb.nodesource.com/setup_19.x | bash - && apt-get install -y nodejs

...

COPY assets assets

+ # install all npm packages in assets directory
+ WORKDIR /app/assets
+ RUN npm install

+ # change back to build dir
+ WORKDIR /app

...

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
-  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
+  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates curl \
   && apt-get clean && rm -f /var/lib/apt/lists/*_*

+ # install nodejs for production environment
+ RUN curl -fsSL https://deb.nodesource.com/setup_19.x | bash - && apt-get install -y nodejs

...
```

Note: `nodejs` is installed BOTH in the build stage and in the final image. This is because we need `nodejs` to install our `npm` dependencies and also need it when running our app.

3. Launch your app with the Fly.io CLI:

```bash
fly launch
```

4. When prompted to tweak settings, choose `y`:

```bash
? Do you want to tweak these settings before proceeding? (y/N) y
```

This will launch a new window where you can tweak your launch settings. In the database section, choose `Fly Postgres` and enter a name for your database. You may also want to change your database to the development configuration to avoid extra costs. You can leave the rest of the settings as-is unless you want to change them.

Deployment will continue once you hit confirm.

5. Once the deployment completes, run the following command to see your deployed app!

```bash
fly apps open
```

## FAQ

### Name sounds exaclty the same as LiveView

Yes, I noticed it slightly too late to change. Some helpful reddit users pointed it out 😉

I'd suggest refering to it as `LiveVuejs` in speech, to avoid confusion.

### Differences from LiveSvelte

Both `LiveVue` and `LiveSvelte `serves the same purpose and are implemented in a very similar way. Here is a list of points to consider when choosing one over another:

-   Vue uses virtual DOM, Svelte doesn't. Vue bundle is slightly bigger than Svelte because of runtime.
-   Vue performance is very similar, or even better, than Svelte. Both are fast enough that you shouldn't make your decision based on it.
-   Vue is working on a [Vapor mode](https://github.com/vuejs/core-vapor) without virtual DOM. Once stable I'll try to support it here.
-   Svelte reactivity is done based on the compilation step figuring out dependencies. It allows for a very concise syntax, but causes probles when you'd like to keep reactivity cross-files and [has some limitations](https://thoughtspile.github.io/2023/04/22/svelte-state/). Svelte 5 Runes will be very similar to Vue `ref`.
-   Vue reactivity is [based on JS Proxies](https://vuejs.org/guide/extras/reactivity-in-depth.html#how-reactivity-works-in-vue). Syntax is a bit more verbose, but there are less ways to shoot yourself in a foot 😉
-   Vue is more popular than Svelte, and has a bigger ecosystem. It might be an important thing to consider when making a decision.

### Colocating Vue files alongside your LiveViews

Vue files in LiveVue have similar role as HEEX templates. In many cases it makes sense to [colocate them next to your LiveViews for better DX](https://elixirforum.com/t/discussion-about-domain-orientated-folder-structures-in-phoenix/17190).

You don't need to do anything to make it work, simply place your Vue files inside `lib/my_app_web` directory and reference them by their names or relative paths.

### How does it work?

The idea is fairly simple.

1. Phoenix [renders](https://github.com/Valian/live_vue/blob/main/lib/live_vue.ex) a `div` with props, slots and handlers as `data` attributes. In live views these are kept in sync. When SSR is enabled, it also renders the component and inlines the result in the HTML.
2. `LiveVue` [hook](https://github.com/Valian/live_vue/blob/main/assets/js/live_vue/hooks.js) `mount` callback initializes the element. It hooks up all the handlers, injects hook itself so `useLiveVue` works correctly, and mounts the Vue component.
3. On update, Phoenix only changes data attributes. Hook updates props of the element.
4. On destroy, Vue element is unmounted and garbage collected.

One thing to keep in mind is that hooks are fired only after `app.js` is fully loaded, so it might cause some delays of the initial render of the component.

### Why SSR is useful?

As explained in the previous section, it takes a moment for Vue component to initialize, even if props are already inlined in the HTML.

It's done only during a "dead" render, without connected socket. It's not needed when doing live navigation - in my experience when using `<.link navigate="...">` component is rendered before displaying a new page.

### Component lazy loading

Not yet possible. Tracked in [this issue](https://github.com/Valian/live_vue/issues/3).

## Credits

[LiveSvelte](https://github.com/woutdp/live_svelte)

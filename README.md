<div align="center">
    <img src="https://github.com/Valian/live_vue/blob/main/live_vue_logo_rounded.png?raw=true" alt="Description" height="256px">
<br>
<a href="https://hex.pm/packages/live_vue"><img src="https://img.shields.io/hexpm/v/live_vue.svg" alt="Hex.pm"></a>
<a href="https://hexdocs.pm/live_vue"><img src="https://img.shields.io/badge/docs-hexdocs.pm-purple" alt="Hexdocs.pm"></a>
<a href="https://github.com/Valian/live_vue"><img src="https://img.shields.io/github/stars/Valian/live_vue?style=social" alt="GitHub"></a>
<br><br>
Vue inside Phoenix LiveView with seamless end-to-end reactivity.
</div>

## Features

-   ⚡ **End-To-End Reactivity** with LiveView
-   🔋 **Server-Side Rendered** (SSR) Vue
-   🐌 **Lazy-loading** Vue Components
-   📦 **Efficient Props Diffing** - Only changed data is sent over WebSocket
-   🪄 **Sigil** as an [Alternative LiveView DSL](#using-v-sigil-to-inline-vue-components)
-   🦄 **Tailwind** Support
-   💀 **Dead View** Support
-   🦥 **Slot Interoperability**
-   🚀 **Amazing DX** with Vite


## Resources

-   [HexDocs](https://hexdocs.pm/live_vue)
-   [HexPackage](https://hex.pm/packages/live_vue)
-   [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view)

## Example

After installation, you can use Vue components in the same way as you'd use functional LiveView components. You can even handle Vue events with `JS` hooks! All the `phx-click`, `phx-change` attributes works inside Vue components as well.

```html
<script setup lang="ts">
import {ref} from "vue"

// props are passed from LiveView
const props = defineProps<{count: number}>()

// local state
const diff = ref(1)
</script>

<template>
  Current count: {{ props.count }}
  <label>Diff: </label>
  <input v-model.number="diff" type="range" min="1" max="10" />

  <button phx-click="inc" :phx-value-diff="diff">
    Increase counter by {{ diff }}
  </button>
</template>
```

```elixir
defmodule MyAppWeb.CounterLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~H"""
    <.vue count={@count} v-component="Counter" v-socket={@socket} />
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("inc", %{"diff" => value}, socket) do
    {:noreply, update(socket, :count, &(&1 + value))}
  end
end
```

## Why?

Phoenix Live View makes it possible to create rich, interactive web apps without writing JS.

But once you'll need to do anything even slightly complex on the client-side, you'll end up writing lots of imperative, hard-to-maintain hooks.

LiveVue allows to create hybrid apps, where part of the session state is on the server and part on the client.

### Reasons why you'd like to use LiveVue

-   Your hooks are starting to look like jQuery
-   You have a complex local state
-   You'd like to use a massive Vue ecosystem
-   You want transitions, graphs etc.
-   You simply like Vue 😉

## Installation

See [Installation](guides/installation.md).

## Guides

### Getting Started
 - [Getting Started](guides/getting_started.md) - Create your first Vue component with transitions

### Core Usage
 - [Basic Usage](guides/basic_usage.md) - Fundamental patterns, ~V sigil, and common examples
 - [Configuration](guides/configuration.md) - Advanced setup, SSR, and customization options

### Reference
 - [Component Reference](guides/component_reference.md) - Complete syntax documentation
 - [Client-Side API](guides/client_api.md) - Vue composables and utilities

### Advanced Topics
 - [Architecture](guides/architecture.md) - How LiveVue works under the hood
 - [Testing](guides/testing.md) - Testing Vue components in LiveView
 - [Deployment](guides/deployment.md) - Production deployment guide

### Help & Troubleshooting
 - [FAQ](guides/faq.md) - Common questions and comparisons
 - [Troubleshooting](guides/troubleshooting.md) - Debug common issues
 - [Comparison](guides/comparison.md) - LiveVue vs other solutions

## Relation to LiveSvelte

This project is heavily inspired by ✨ [LiveSvelte](https://github.com/woutdp/live_svelte) ✨. Both projects try to solve the same problem. LiveVue was started as a fork of LiveSvelte with adjusted ESbuild settings, and evolved to use Vite and a slightly different syntax. I strongly believe more options are always better, and since I love Vue and it's ecosystem I've decided to give it a go 😉

You can read more about differences between Vue and Svelte [in FAQ](#differences-from-livesvelte).

## LiveVue Development

### Local Setup

Ensure you have node installed. Clone the repo and run `mix setup`. You can then run `mix assets.watch` to start a watcher for the assets.

#### Example Project

You can use `/example_project` as a way to test `live_vue` locally.

- Clone this repo
- Go to example_project dir
- Run `mix setup`
- Run `mix phx.server` to start the server
- Open [http://localhost:4000](http://localhost:4000) in your browser


### Building Static Files

LiveVue is written in TypeScript. To see the changes you made, you have to recompile the assets. You can do it with:

```bash
mix assets.build
```

Or run the watcher:

```bash
mix assets.watch
```

### Releasing

Release is done with `expublish` package.

-   Write version changelog in untracked `RELEASE.md` file
-   Update version in `INSTALLATION.md`

Run

```bash
git add INSTALLATION.md
git commit -m "INSTALLATION version bump"

# to ensure everything works fine
mix expublish.minor --dry-run --allow-untracked --branch=main

# to publish everything
mix do assets.build, expublish.minor --allow-untracked --branch=main
```

## Roadmap 🎯

- [ ] Add a default handler for Vue emits to eg. automatically push them to the server without explicit `v-on` handlers.
- [ ] try to use [Igniter](https://hexdocs.pm/igniter/) as a way of installing LiveVue in a project
- [ ] `usePushEvent` - an utility similar to [`useFetch`](https://vueuse.org/core/useFetch/) making it easy to get data from `&handle_event/3 -> {:reply, data, socket}` responses
- [ ] `useLiveForm` - an utility to efforlessly use Ecto changesets & server-side validation, similar to HEEX
- [ ] `useEventHandler` - an utility automatically attaching & detaching [`handleEvent`](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook)
- [x] ~~optimize payload - send only [`json_patch`](https://hexdocs.pm/jsonpatch/readme.html) diffs of updated props~~ ✅ **Done!**
- [ ] VS code extension highlighting `~V` sigil
- [ ] Add support for Phoenix streams as props

## Credits

[LiveSvelte](https://github.com/woutdp/live_svelte)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Valian/live_vue&type=Date)](https://star-history.com/#Valian/live_vue&Date)

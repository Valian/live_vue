# Basic Usage

This guide covers the fundamental patterns for using Vue components within LiveView.

## Component Organization

By default, Vue components should be placed in either:
- `assets/vue` directory
- Colocated with your LiveView files in `lib/my_app_web`

See [Configuration](configuration.html) to learn how to configure the component resolution.

## Rendering Components

### Basic Syntax

To render a Vue component from HEEX, use the `<.vue>` function:

```elixir
<.vue
  count={@count}
  v-component="Counter"
  v-socket={@socket}
  v-on:inc={JS.push("inc")}
/>
```

### Required Attributes

| Attribute    | Example                | Required        | Description                                    |
|--------------|------------------------|-----------------|------------------------------------------------|
| v-component  | `v-component="Counter"`| Yes            | Component name or path relative to vue_root    |
| v-socket     | `v-socket={@socket}`   | Yes in LiveView| Required for SSR and reactivity               |

### Optional Attributes

| Attribute    | Example              | Description                                    |
|--------------|----------------------|------------------------------------------------|
| v-ssr        | `v-ssr={true}`      | Override default SSR setting                   |
| v-on:event   | `v-on:inc={JS.push("inc")}` | Handle Vue component events           |
| prop={@value}| `count={@count}`     | Pass props to the component                   |

### Component Shortcut

Instead of writing `<.vue v-component="Counter">`, you can use the shortcut syntax:

```elixir
<.Counter count={@count} v-socket={@socket} />
```

Function names are generated based on `.vue` file names. For files with identical names, use the full path:

```elixir
<.vue v-component="helpers/nested/Modal" />
```

## Passing Props

Props can be passed in three equivalent ways:

```elixir
# Individual props
<.vue count={@count} max={123} v-component="Counter" v-socket={@socket} />

# Map spread
<.vue v-component="Counter" v-socket={@socket} {@props} />

# Using shortcut - you don't have to specify v-component
<.Counter count={@count} max={123} v-socket={@socket} />
```

## Handling Events

### Phoenix Events

All standard Phoenix event handlers work inside Vue components:
- `phx-click`
- `phx-change`
- `phx-submit`
- etc.

They will be pushed directly to LiveView, exactly as happens with `HEEX` components.

### Vue Events

If you want to create reusable Vue components where you'd like to define what happens when Vue emits an event, you can use the `v-on:` syntax with `JS` [module helpers](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html#module-client-utility-commands).

```elixir
<.vue
  v-on:submit={JS.push("submit")}
  v-on:close={JS.hide()}
  v-component="Form"
  v-socket={@socket}
/>
```

Special case: When using `JS.push()` without a value, it automatically uses the emit payload:
```elixir
# In Vue
emit('inc', {value: 5})

# In LiveView
<.vue v-on:inc={JS.push("inc")} />
# Equivalent to: JS.push("inc", value: 5)
```

## Slots Support

Vue components can receive slots from LiveView templates:

```elixir
<.Card title="Example Card" v-socket={@socket}>
  <p>This is the default slot content!</p>
  <p>Phoenix components work too: <.icon name="hero-info" /></p>

  <:footer>
    This is a named slot
  </:footer>
</.Card>
```

```html
<template>
  <div>
    <!-- Default slot -->
    <slot></slot>

    <!-- Named slot -->
    <slot name="footer"></slot>
  </div>
</template>
```

Important notes about slots:
- Each slot is wrapped in a div (technical limitation)
- You can use HEEX components inside slots 🥳
- Slots stay reactive and update when their content changes


> #### Hooks inside slots are not supported {: .warning}
>
> Slots are rendered server-side and then sent to the client as a raw HTML.
> It happens outside of the LiveView lifecycle, so hooks inside slots are not supported.
>
> As a consequence, since `.vue` components rely on hooks, it's not possible to nest `.vue` components inside other `.vue` components.


## Dead Views vs Live Views

Components can be used in both contexts:
- Live Views: Full reactivity with WebSocket updates
- Dead Views: Static rendering, no reactivity
  - `v-socket={@socket}` not required
  - SSR still works for initial render

## Client-Side Hooks

Access Phoenix hooks from Vue components using `useLiveVue`:

```html
<script setup>
import {useLiveVue} from "live_vue"

const live = useLiveVue()
live.pushEvent("hello", {value: "world"})
live.handleEvent("response", (payload) => { console.log(payload) })
</script>
```

The `live` object provides all methods from [Phoenix.LiveView JS Interop](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook).

## Next Steps

Now that you understand the basics, you might want to explore:

- [Advanced Features](advanced_features.html) to learn about:
  - Using the `~V` sigil for inline Vue components
  - Lazy loading components
  - Customizing the Vue app instance
  - SSR configuration and optimization
- [FAQ](faq.html) for:
  - Understanding how LiveVue works under the hood
  - Performance optimizations
  - TypeScript setup
  - Comparison with LiveSvelte
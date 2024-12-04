# Basic Usage

This guide covers the fundamental patterns for using Vue components within LiveView.

## Component Organization

By default, Vue components should be placed in either:
- `assets/vue` directory
- Colocated with your LiveView files in `lib/my_app_web`

You can configure these paths by:
1. Modifying `assets/vue/index.js`
2. Adjusting the LiveVue.Components configuration:
```elixir
use LiveVue.Components, vue_root: ["your/vue/dir"]
```

## Rendering Components

### Basic Syntax

To render a Vue component from HEEX, use the `<.vue>` function:

```elixir
<.vue
  v-component="Counter"
  v-socket={@socket}
  count={@count}
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
<.Counter
  count={@count}
  v-socket={@socket}
/>
```

Function names are generated based on `.vue` file names. For files with identical names, use the full path:
```elixir
<.vue v-component="helpers/nested/Modal" />
```

## Passing Props

Props can be passed in three equivalent ways:

```elixir
# Individual props
<.vue
  count={@count}
  name={@name}
  v-component="Counter"
  v-socket={@socket}
/>

# Map spread
<.vue
  v-component="Counter"
  v-socket={@socket}
  {%{count: @count, name: @name}}
/>

# Using shortcut
<.Counter
  count={@count}
  name={@name}
  v-socket={@socket}
/>
```

## Handling Events

### Phoenix Events

All standard Phoenix event handlers work inside Vue components:
- `phx-click`
- `phx-change`
- `phx-submit`
- etc.

### Vue Events

For Vue-specific events, use the `v-on:` syntax:

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

```vue
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
- Slots are passed as raw HTML
- Phoenix hooks in slots won't work
- Slots stay reactive and update when their content changes

## Dead Views vs Live Views

Components can be used in both contexts:
- Live Views: Full reactivity with WebSocket updates
- Dead Views: Static rendering, no reactivity
  - `v-socket={@socket}` not required
  - SSR still works for initial render

## Client-Side Hooks

Access Phoenix hooks from Vue components using `useLiveVue`:

```vue
<script setup>
import {useLiveVue} from "live_vue"

const hook = useLiveVue()
hook.pushEvent("hello", {value: "from Vue"})
</script>
```

The hook provides all methods from [Phoenix.LiveView JS Interop](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook).

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
# Basic Usage

This guide covers the fundamental patterns for using Vue components within LiveView.

## Component Organization

By default, Vue components should be placed in either:
- `assets/vue` directory
- Colocated with your LiveView files in `lib/my_app_web`

For advanced component organization and custom resolution patterns, see [Configuration](configuration.html#component-organization).

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

### Programmatic access to hook instance

Access Phoenix hooks from Vue components using `useLiveVue`:

```html
<script setup>
import {useLiveVue} from "live_vue"

const live = useLiveVue()
live.pushEvent("hello", {value: "world"})
live.handleEvent("response", (payload) => { console.log(payload) })
</script>

<template>
  <!-- Can be used from template as well -->
  <button @click="live.pushEvent('hello', {value: 'world'})">Click me</button>
</template>
```

The `live` object provides all methods from [Phoenix.LiveView JS Interop](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook). For a complete API reference, see [Client-Side API](client_api.html).

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

## Using ~V Sigil

The `~V` sigil provides an alternative to the standard LiveView DSL, allowing you to write Vue components directly in your LiveView:

```elixir
defmodule MyAppWeb.CounterLive do
  use MyAppWeb, :live_view

  def render(assigns) do
    ~V"""
    <script setup lang="ts">
    import {ref} from "vue"
    const props = defineProps<{count: number}>()
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

This approach is great when you want to keep everything in one file or when prototyping components quickly.

## Next Steps

Now that you understand the basics, you might want to explore:

- [Component Reference](component_reference.html) for complete syntax documentation
- [Configuration](configuration.html) for advanced setup and customization options
- [Client-Side API](client_api.html) for detailed API reference and advanced patterns
- [FAQ](faq.html) for common questions and troubleshooting
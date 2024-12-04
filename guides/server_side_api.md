# Server-Side API

This guide covers LiveView integration patterns when using Vue components with LiveVue.

## Component Rendering

### The `<.vue>` Component

The primary way to render Vue components from LiveView is with the `<.vue>` function component:

```elixir
<.vue
  v-component="Counter"
  v-socket={@socket}
  count={@count}
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
<.Counter
  count={@count}
  v-socket={@socket}
/>
```

Function names are generated based on `.vue` file names. For files with identical names, use the full path:
```elixir
<.vue v-component="helpers/nested/Modal" />
```

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

### Prop Requirements

- Props must be serializable with `Jason.encode!/1`
- Structures need to implement the `Jason.Encoder` protocol
- Avoid passing functions or PIDs as props

## Handling Events

### Phoenix Events

Standard Phoenix event attributes work in Vue components:
- `phx-click`
- `phx-change`
- `phx-submit`
- etc.

### Vue-Specific Events

For Vue-emitted events, use the `v-on:` syntax:

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

### Event Handling in LiveView

Handle events from Vue components like any other LiveView event:

```elixir
def handle_event("inc", %{"value" => value}, socket) do
  {:noreply, update(socket, :count, &(&1 + value))}
end
```

## Using Slots

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

Important notes about slots:
- Default slot content uses `<:inner_block>` in Vue
- Named slots use `<:slot_name>` in LiveView and `<slot name="slot_name">` in Vue
- Each slot is wrapped in a div (technical limitation)
- Slots are passed as raw HTML
- Phoenix hooks in slots won't work
- Slots stay reactive and update when their content changes

## Dead Views vs Live Views

Components can be used in both contexts:
- Live Views: Full reactivity with WebSocket updates
- Dead Views: Static rendering, no reactivity
  - `v-socket={@socket}` not required in dead views
  - SSR still works for initial render

## Navigation Between LiveViews

Use the `<LiveLink>` component from your Vue files for LiveView navigation:

```vue
<template>
  <!-- LiveView navigation without full page reload -->
  <LiveLink to="/other-page" class="...">Go to Other Page</LiveLink>

  <!-- LiveView patch (update current LiveView) -->
  <LiveLink patch to="/current-page?tab=other" class="...">Change Tab</LiveLink>
</template>
```

## Server-Side Rendering (SSR)

LiveVue provides SSR capabilities for Vue components:

```elixir
# Enable/disable globally
config :live_vue, ssr: true

# Override per component
<.vue v-ssr={false} v-component="NoSSR" />
```

Benefits of SSR:
- Faster initial page load
- Better SEO
- Works without JavaScript
- Reduces layout shift

## Next Steps

Now that you understand the server-side integration, explore:
- [Client-Side API](client_side_api.html) for Vue component patterns
- [Advanced Features](advanced_features.html) for more LiveVue capabilities

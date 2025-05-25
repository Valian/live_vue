# Component Reference

This guide provides a complete reference for using Vue components in Phoenix LiveView templates.

## The `.vue` Component

The `.vue` component is the primary way to render Vue components in LiveView templates.

### Basic Syntax

```elixir
<.vue
  v-component="ComponentName"
  v-socket={@socket}
  prop_name={@value}
/>
```

### Required Attributes

| Attribute | Type | Description | Example |
|-----------|------|-------------|---------|
| `v-component` | `string` | Vue component name or path | `"Counter"`, `"admin/Dashboard"` |
| `v-socket` | `Phoenix.LiveView.Socket` | LiveView socket (required in LiveView) | `{@socket}` |

### Optional Attributes

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `id` | `string` | auto-generated | Explicit wrapper element ID |
| `class` | `string` | `nil` | CSS classes for wrapper element |
| `v-ssr` | `boolean` | `true` | Enable/disable server-side rendering |

### Event Handlers

Event handlers use the `v-on:` prefix to handle Vue component events.

| Pattern | Description | Example |
|---------|-------------|---------|
| `v-on:event-name` | Handle Vue emit events | `v-on:save={JS.push("save")}` |

### Props

All other attributes are passed as props to the Vue component. They are JSON-encoded - you need to either provide serializable types or implement [Jason.Encoder protocol](https://hexdocs.pm/jason/Jason.Encoder.html) for your custom types.

```elixir
<.vue
  v-component="UserProfile"
  v-socket={@socket}
  user={@user}
  settings={@settings}
  is_admin={@current_user.admin?}
  count={42}
  items={@list}
/>
```

## Component Shortcuts

When using `LiveVue.Components`, you can use shortcut syntax instead of the full `v-component` attribute.

### Setup

```elixir
# In lib/my_app_web.ex
defp html_helpers do
  quote do
    use LiveVue.Components, vue_root: [
      "./assets/vue",
      "./lib/my_app_web"
    ]
  end
end
```

### Usage

```elixir
# Instead of
<.vue v-component="Counter" v-socket={@socket} count={@count} />

# You can use
<.Counter v-socket={@socket} count={@count} />
```

### Component Resolution

Components are resolved by file name.

| File Path | Component Name | Shortcut |
|-----------|----------------|----------|
| `assets/vue/Counter.vue` | `"Counter"` | `<.Counter />` |
| `assets/vue/admin/Dashboard.vue` | `"Dashboard"` | `<.Dashboard />` |

For components with identical names, use `.vue` component with unambiguous path:
```elixir
<.vue v-component="admin/Modal" v-socket={@socket} />
<.vue v-component="public/Modal" v-socket={@socket} />
```

## Slots

Vue components can receive slots from LiveView templates.

### Basic Slots

```elixir
<.vue v-component="Card" v-socket={@socket}>
  <p>This content goes to the default slot</p>
  <.icon name="hero-star" />
</.vue>
```

```vue
<!-- Card.vue -->
<template>
  <div class="card">
    <slot></slot>
  </div>
</template>
```

### Named Slots

```elixir
<.vue v-component="Modal" v-socket={@socket}>
  <:header>
    <h2>Modal Title</h2>
  </:header>

  <p>Modal content goes here</p>

  <:footer>
    <button>Cancel</button>
    <button>Save</button>
  </:footer>
</.vue>
```

```vue
<!-- Modal.vue -->
<template>
  <div class="modal">
    <header>
      <slot name="header"></slot>
    </header>

    <main>
      <slot></slot>
    </main>

    <footer>
      <slot name="footer"></slot>
    </footer>
  </div>
</template>
```

### Slot Limitations

- Each slot is wrapped in a `div` element (technical limitation)
- Slots are rendered server-side, so they can't contain Vue components
- Phoenix hooks don't work inside slots
- Slots remain reactive and update when their content changes

## Event Handling

### Phoenix Events (Recommended)

Standard Phoenix events work directly in Vue components:

```elixir
<.vue v-component="Form" v-socket={@socket}>
  <!-- These work inside Vue components -->
  <button phx-click="save">Save</button>
  <input phx-change="validate" />
  <form phx-submit="submit">...</form>
</.vue>
```

### Vue Event Handlers

Use `v-on:` for handling Vue component events:

```elixir
<.vue
  v-component="Counter"
  v-socket={@socket}
  count={@count}
  v-on:increment={JS.push("inc")}
  v-on:decrement={JS.push("dec")}
  v-on:reset={JS.push("reset")}
/>
```

```vue
<!-- Counter.vue -->
<script setup>
const emit = defineEmits(['increment', 'decrement', 'reset'])

const increment = () => emit('increment', { amount: 1 })
const decrement = () => emit('decrement', { amount: 1 })
const reset = () => emit('reset')
</script>
```

### Event Payload Handling

When using `JS.push()` without a value, the emit payload is automatically used:

```vue
<!-- Vue component -->
<button @click="$emit('save', { data: formData })">Save</button>
```

```elixir
<!-- LiveView template -->
<.vue v-on:save={JS.push("save")} />
<!-- Equivalent to: JS.push("save", data: formData) -->
```

### Complex Event Handlers

```elixir
<.vue
  v-component="DataTable"
  v-socket={@socket}
  v-on:sort={JS.push("sort") |> JS.patch("/sorted")}
  v-on:filter={JS.push("filter") |> JS.show(to: "#loading")}
  v-on:export={JS.push("export") |> JS.navigate("/download")}
/>
```

## Server-Side Rendering (SSR)

### Global SSR Configuration

See [Configuration](configuration.html) for more details.

### Per-Component SSR Control

```elixir
<!-- Enable SSR for this component -->
<.vue v-component="HeavyComponent" v-ssr={true} v-socket={@socket} />

<!-- Disable SSR for this component -->
<.vue v-component="ClientOnlyWidget" v-ssr={false} v-socket={@socket} />

<!-- Use global default -->
<.vue v-component="RegularComponent" v-socket={@socket} />
```

### SSR Behavior

| Context | SSR Enabled | Behavior |
|---------|-------------|----------|
| Initial page load | Yes | Component rendered on server |
| Live navigation | No | Client-side rendering only |
| WebSocket update | No | Client-side rendering only |
| Dead view | Yes | Server-side rendering |

## Data Types and Serialization

### Supported Prop Types

| Elixir Type | Vue Type | Example |
|-------------|----------|---------|
| `string` | `string` | `name={"John"}` |
| `integer` | `number` | `count={42}` |
| `float` | `number` | `price={19.99}` |
| `boolean` | `boolean` | `active={true}` |
| `list` | `array` | `items={[1, 2, 3]}` |
| `map` | `object` | `user={%{name: "John"}}` |
| `nil` | `null` | `optional={nil}` |

### Complex Data Structures

```elixir
<.vue
  v-component="UserDashboard"
  v-socket={@socket}
  user={%{
    id: 1,
    name: "John Doe",
    email: "john@example.com",
    preferences: %{
      theme: "dark",
      notifications: true
    }
  }}
  permissions={["read", "write", "admin"]}
  metadata={%{
    last_login: ~U[2023-01-01 12:00:00Z],
    login_count: 42
  }}
/>
```

### Date and Time Handling

```elixir
# Dates are serialized as ISO strings
<.vue
  v-component="Calendar"
  v-socket={@socket}
  current_date={Date.utc_today()}
  created_at={DateTime.utc_now()}
/>
```

```vue
<!-- Vue component -->
<script setup>
const props = defineProps<{
  current_date: string  // "2023-12-01"
  created_at: string    // "2023-12-01T12:00:00Z"
}>()

// Convert to JavaScript Date objects
const currentDate = new Date(props.current_date)
const createdAt = new Date(props.created_at)
</script>
```

## Error Handling

### Component Not Found

```elixir
<!-- This will log an error to the console if Counter.vue doesn't exist -->
<.vue v-component="Counter" v-socket={@socket} />
```

### Invalid Props

```elixir
<!-- Vue will warn in console about type mismatches in development -->
<.vue
  v-component="UserProfile"
  v-socket={@socket}
  user_id="not-a-number"  <!-- Should be integer -->
/>
```

### SSR Errors

```elixir
<!-- SSR errors are logged but don't break the page -->
<.vue v-component="ProblematicComponent" v-ssr={true} v-socket={@socket} />
```

## Performance Considerations

### Prop Optimization

```elixir
# ✅ Good: Only pass what's needed
<.vue
  v-component="UserCard"
  v-socket={@socket}
  user={%{name: @user.name, avatar: @user.avatar}}
/>

# ❌ Avoid: Passing large objects unnecessarily
<.vue
  v-component="UserCard"
  v-socket={@socket}
  user={@user}  # Contains many unused fields
/>
```

## Best Practices

### Component Organization

```elixir
# ✅ Good: Descriptive component names
<.vue v-component="UserProfileCard" v-socket={@socket} />
<.vue v-component="admin/UserManagementTable" v-socket={@socket} />

# ❌ Avoid: Generic names
<.vue v-component="Component" v-socket={@socket} />
<.vue v-component="Widget" v-socket={@socket} />
```

### Prop Naming

```elixir
# ✅ Good: Clear, descriptive prop names
<.vue
  v-component="ProductCard"
  v-socket={@socket}
  product_name={@product.name}
  is_featured={@product.featured?}
  price_in_cents={@product.price}
/>

# ❌ Avoid: Ambiguous prop names
<.vue
  v-component="ProductCard"
  v-socket={@socket}
  name={@product.name}
  flag={@product.featured?}
  amount={@product.price}
/>
```

### Event Naming

```elixir
# ✅ Good: Descriptive event names
<.vue
  v-component="ShoppingCart"
  v-socket={@socket}
  v-on:item-added={JS.push("add_item")}
  v-on:checkout-started={JS.push("start_checkout")}
/>

# ❌ Avoid: Generic event names
<.vue
  v-component="ShoppingCart"
  v-socket={@socket}
  v-on:click={JS.push("handle_click")}
  v-on:action={JS.push("do_action")}
/>
```

## Common Patterns

### Data Display Components

```elixir
<.vue
  v-component="DataTable"
  v-socket={@socket}
  items={@users}
  columns={["name", "email", "created_at"]}
  sortable={true}
  v-on:sort={JS.push("sort_users")}
  v-on:filter={JS.push("filter_users")}
/>
```

## Troubleshooting

### Component Not Rendering

1. Check component name spelling and case sensitivity
2. Verify `v-socket={@socket}` is present in LiveView
3. Ensure component file exists in configured paths
4. Check browser console for JavaScript errors

### Props Not Updating

1. Verify prop names match between LiveView and Vue
2. Check that LiveView assigns are actually changing
3. Ensure `@socket` is connected (not in dead view)

### Events Not Working

1. Check event name spelling in both Vue emit and LiveView handler
2. Verify `handle_event/3` function exists in LiveView
3. Check event payload structure matches expectations

## Next Steps

- [Client-Side API](client_api.html) for Vue component development
- [Basic Usage](basic_usage.html) for common patterns and examples
- [Advanced Features](advanced_features.html) for complex scenarios
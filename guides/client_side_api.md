# Client-Side API

This guide covers the client-side aspects of working with Vue components in LiveVue.

## Vue Component Structure

LiveVue supports modern Vue 3 composition API with `<script setup>` syntax:

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useLiveVue } from 'live_vue'

// Props with TypeScript
const props = defineProps<{
  count: number
  title?: string
}>()

// Emits with TypeScript
const emit = defineEmits<{
  inc: [{value: number}]
  close: []
}>()

// Local reactive state
const localValue = ref(0)

// Computed properties
const doubleCount = computed(() => props.count * 2)

// Lifecycle hooks
onMounted(() => {
  console.log('Component mounted')
})

// Handle a click
const handleClick = () => {
  emit('inc', { value: localValue.value })
}
</script>

<template>
  <div>
    <h1>{{ title || 'Default Title' }}</h1>
    <p>Count: {{ count }}</p>
    <p>Double: {{ doubleCount }}</p>
    <input v-model="localValue" type="number" />
    <button @click="handleClick">
      Increment by {{ localValue }}
    </button>
  </div>
</template>
```

## LiveVue Integration Hooks

### The `useLiveVue` Composable

Access Phoenix LiveView functionality directly from Vue:

```vue
<script setup>
import { useLiveVue } from 'live_vue'

// Get the LiveView hook
const hook = useLiveVue()

// Push an event to the server
const sendToServer = () => {
  hook.pushEvent('my-event', { data: 'value' })
}

// Handle server events
hook.handleEvent('server-event', (payload) => {
  console.log('Server sent:', payload)
})
</script>
```

Available methods from the hook:
- `pushEvent(event, payload)`: Send data to the server
- `pushEventTo(selector, event, payload)`: Send data to a specific LiveView
- `handleEvent(event, callback)`: Listen for server events
- All methods from [Phoenix.LiveView JS Interop](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook)

## Navigation Components

LiveVue provides the `<LiveLink>` component for navigating between LiveViews:

```vue
<script setup>
import { LiveLink } from 'live_vue'
</script>

<template>
  <!-- Standard navigation (full page) -->
  <LiveLink to="/about" class="...">About</LiveLink>

  <!-- LiveView navigation (keeps layout) -->
  <LiveLink navigate to="/dashboard" class="...">Dashboard</LiveLink>

  <!-- LiveView patch (partial update) -->
  <LiveLink patch to="/products?page=2" replace class="...">Next Page</LiveLink>
</template>
```

Link options:
- `to`: Target URL (required)
- `navigate`: Use LiveView navigation
- `patch`: Use LiveView patch
- `replace`: Replace URL history instead of pushing
- All standard HTML attributes (class, id, etc.)

## Component Communication Patterns

### Prop-Down, Event-Up

The recommended pattern for LiveVue component communication:

LiveView (state) --> Props --> Vue Component
LiveView <-- Events <-- Vue Component

Example:
```elixir
# LiveView
<.vue
  items={@items}
  v-on:add={JS.push("add")}
  v-on:remove={JS.push("remove")}
/>

# Event handler
def handle_event("add", %{"item" => item}, socket) do
  {:noreply, update(socket, :items, &[item | &1])}
end
```

```vue
<!-- Vue component -->
<script setup>
const props = defineProps(['items'])
const emit = defineEmits(['add', 'remove'])
</script>
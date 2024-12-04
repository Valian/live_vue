# Getting Started

Now that you have LiveVue installed, let's create your first Vue component and integrate it with LiveView.

## Creating Your First Component

Let's create a simple counter component that demonstrates the reactivity between Vue and LiveView.

1. Create `assets/vue/Counter.vue`:

```vue
<script setup lang="ts">
import {ref} from "vue"
const props = defineProps<{count: number}>()
const emit = defineEmits<{inc: [{value: number}]}>()
const diff = ref<string>("1")
</script>

<template>
  <div class="max-w-sm mx-auto p-6 bg-white rounded-lg shadow-md">
    <h2 class="text-xl font-bold mb-4">Current count: {{ props.count }}</h2>

    <label class="block mb-2">Increment by:</label>
    <input
      v-model="diff"
      type="range"
      min="1"
      max="10"
      class="w-full mb-4"
    />

    <button
      @click="emit('inc', {value: parseInt(diff)})"
      class="w-full bg-blue-500 text-white rounded px-4 py-2 hover:bg-blue-600"
    >
      Increase by {{ diff }}
    </button>
  </div>
</template>
```

2. Create a LiveView to handle the counter state (`lib/my_app_web/live/counter_live.ex`):

```elixir
defmodule MyAppWeb.CounterLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

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

  def handle_event("inc", %{"value" => value}, socket) do
    {:noreply, update(socket, :count, &(&1 + value))}
  end
end
```

3. Add the route in your `router.ex`:

```elixir
live "/counter", CounterLive
```

## Understanding How It Works

This example demonstrates several key LiveVue features:

- **Props Flow**: LiveView sends the `count` value to Vue as a prop
- **Event Handling**: Vue emits an `inc` event that LiveView captures with `JS.push("inc")`
- **State Management**: LiveView maintains the source of truth (the counter value)
- **Local UI State**: Vue maintains the slider value locally without server involvement

Let's see what's happening step-by-step:

1. When a user loads the page, LiveView renders the Vue component with the initial count of 0
2. Vue receives this value as a prop and displays it
3. As the user moves the slider, Vue updates its local state without server communication
4. When the user clicks the button:
   - Vue emits an `inc` event with the current slider value
   - LiveView receives this event via `v-on:inc={JS.push("inc")}`
   - The `handle_event("inc", ...)` function updates the counter
   - LiveView re-renders, sending the new count back to Vue
   - Vue updates to display the new value

## Component Placement Options

You can place Vue components in two locations:

1. **Assets Directory**: `assets/vue/ComponentName.vue`
   Good for UI components shared across multiple LiveViews

2. **Colocated with LiveViews**: `lib/my_app_web/live/component_name.vue`
   Good for components specific to a single LiveView feature

## Using TypeScript (Recommended)

TypeScript enhances your development experience with Vue:

```vue
<script setup lang="ts">
// Type-safe props
const props = defineProps<{
  count: number
  title?: string  // Optional prop
}>()

// Type-safe emits
const emit = defineEmits<{
  inc: [{value: number}]
  close: []  // Event with no payload
}>()
</script>
```

## Tips

- Install the [Vue DevTools browser extension](https://devtools.vuejs.org/guide/installation.html) for debugging
- In development, LiveVue enables Hot Module Replacement for instant component updates
- Structure your app with LiveView managing application state and Vue handling UI interactions
- For complex UIs with lots of local state, prefer Vue components over LiveView hooks

## Next Steps

Now that you have your first component working, explore:
- [Server-Side API](server_side_api.html) for more LiveView integration patterns
- [Client-Side API](client_side_api.html) for Vue component techniques
- [Advanced Features](advanced_features.html) for SSR, slots, and Vue customization
- [FAQ](faq.html) for common questions and troubleshooting
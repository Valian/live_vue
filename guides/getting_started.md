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

This example demonstrates several key LiveVue features:
- Props passing (`count={@count}`)
- Event handling (`v-on:inc={JS.push("inc")}`)
- Two-way reactivity between Vue and LiveView
- TypeScript support
- Automatic Tailwind integration

## Understanding the Integration

Let's break down how LiveVue connects Vue and LiveView:

1. **Props Flow**: LiveView assigns are passed as props to Vue components

```elixir
count={@count}  # LiveView assign becomes Vue prop
```

2. **Events Flow**: Vue emits are handled by LiveView

```elixir
# In Vue
emit('inc', {value: parseInt(diff)})

# In LiveView
def handle_event("inc", %{"value" => value}, socket) do
```

3. **State Management**: LiveView manages the source of truth, Vue handles local UI state

## Next Steps

Now that you have your first component working, explore:
- [Basic Usage Guide](basic_usage.html) for more component patterns
- [Advanced Features](advanced_features.html) for SSR, slots, and Vue customization
- [FAQ](faq.html) for common questions and troubleshooting

## Tips

- Use the Vue DevTools browser extension for debugging
- Enable [Hot Module Replacement](https://vitejs.dev/guide/features.html#hot-module-replacement) in Vite for better development experience
- Consider colocating Vue components with your LiveViews in `lib/my_app_web/`
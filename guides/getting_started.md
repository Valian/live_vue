# Getting Started

Now that you have LiveVue installed, let's create your first Vue component and integrate it with LiveView.

## Creating Your First Component

Let's create a simple counter component that demonstrates the reactivity between Vue and LiveView.

1. Create `assets/vue/Counter.vue`:

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

2. Create a LiveView to handle the counter state (`lib/my_app_web/live/counter_live.ex`):

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

3. Add the route in your `router.ex`:

```elixir
live "/counter", CounterLive
```

Start server and visit `http://localhost:4000/counter` to see your counter in action!
If it's not working correctly, see [Troubleshooting](troubleshooting.html).

## Adding Smooth Transitions

One of Vue's strengths is its built-in transition system. Let's enhance our counter with smooth animations and nice tailwind styling:

1. Create `assets/vue/AnimatedCounter.vue`:

```html
<script setup lang="ts">
import {ref} from "vue"

const props = defineProps<{count: number}>()
const diff = ref(1)
</script>

<template>
  <div class="space-y-4">
    <div class="text-center">
      <Transition name="count" mode="out-in">
        <span
          :key="props.count"
          class="text-4xl font-bold text-blue-600"
        >
          {{ props.count }}
        </span>
      </Transition>
    </div>

    <div class="flex items-center gap-4">
      <label class="text-sm font-medium">Diff:</label>
      <input
        v-model.number="diff"
        type="range"
        min="1"
        max="10"
        class="flex-1"
      />
      <span class="text-sm text-gray-600">{{ diff }}</span>
    </div>

    <button
      phx-click="inc"
      :phx-value-diff="diff"
      class="w-full px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors"
    >
      Increase by {{ diff }}
    </button>
  </div>
</template>

<style scoped>
.count-enter-active,
.count-leave-active {
  transition: all 0.3s ease;
}

.count-enter-from {
  opacity: 0;
  transform: scale(0.8) translateY(-10px);
}

.count-leave-to {
  opacity: 0;
  transform: scale(1.2) translateY(10px);
}
</style>
```

2. Update your LiveView to use the animated version:

```elixir
def render(assigns) do
  ~H"""
  <div class="max-w-sm mx-auto mt-8 p-6 bg-white rounded-lg shadow-lg">
    <h1 class="text-2xl font-bold mb-6 text-center">Animated Counter</h1>
    <.vue count={@count} v-component="AnimatedCounter" v-socket={@socket} />
  </div>
  """
end
```

Now your counter will smoothly animate when the value changes! This showcases how Vue's transition system can add polish to your LiveView apps without any server-side complexity.

## Key Concepts

This example demonstrates several key LiveVue features:

- **Props Flow**: LiveView sends the `count` value to Vue as a prop
- **Event Handling**: Vue emits an `inc` event with `phx-click` and `phx-value-diff` attributes
- **State Management**: LiveView maintains the source of truth (the counter value)
- **Local UI State**: Vue maintains the slider value locally without server involvement
- **Transitions**: Vue handles smooth animations purely on the client side

Basic diagram of the flow:

![LiveVue flow](./images/lifecycle.png)

If you want to understand how it works in depth, see [Architecture](architecture.html).

### Working with Custom Structs

When you start passing more complex data structures as props, you'll need to implement the `LiveVue.Encoder` protocol:

```elixir
# For any custom structs you want to pass as props
defmodule User do
  @derive LiveVue.Encoder
  defstruct [:name, :email, :age]
end

# Use in your LiveView
def render(assigns) do
  ~H"""
  <.vue user={@current_user} v-component="UserProfile" v-socket={@socket} />
  """
end
```

This protocol ensures that:
- Only specified fields are sent to the client
- Sensitive data is protected from accidental exposure
- Props can be efficiently diffed for optimal performance

For more details, see [Component Reference](component_reference.html#custom-structs-with-livevue-encoder).


> #### Good to know {: .info}
>
> - Install the [Vue DevTools browser extension](https://devtools.vuejs.org/getting-started/installation) for debugging
> - In development, LiveVue enables Hot Module Replacement for instant component updates
> - Structure your app with LiveView managing application state and Vue handling UI interactions
> - For complex UIs with lots of local state, prefer Vue components over LiveView hooks

## Next Steps

Now that you have your first component working, explore:
- [Basic Usage](basic_usage.html) for more patterns and the ~VUE sigil
- [Component Reference](component_reference.html) for complete syntax documentation
- [FAQ](faq.html) for common questions and troubleshooting
- [Troubleshooting](troubleshooting.html) for common issues
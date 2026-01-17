# LiveVue vs Alternatives

This guide compares LiveVue with other Phoenix LiveView frontend integration libraries to help you choose the right solution for your project.

## Overview

LiveVue is part of a growing ecosystem of libraries that integrate modern frontend frameworks with Phoenix LiveView. Each library takes a different approach to solving the challenge of combining server-side state management with rich client-side interactivity.

## Comparison Matrix

| Feature | LiveVue | LiveSvelte | LiveReact | LiveState |
|---------|---------|------------|-----------|-----------|
| **Framework** | Vue.js | Svelte | React | Framework-agnostic |
| **SSR Support** | ✅ | ✅ | ✅ | ❌ |
| **Component Shortcuts** | ✅ | ✅ | ❌ | ❌ |
| **Slots Support** | ✅ | ✅ | ✅ | ❌ |
| **TypeScript Support** | ✅ | ✅ | ✅ | ✅ |
| **Build System** | Vite | Custom esbuild | Vite | Any |
| **Sigil DSL** | ✅ (`~VUE`) | ✅ (`~V`) | ❌ | ❌ |
| **Embeddable Apps** | ❌ | ❌ | ❌ | ✅ |
| **Real-time Updates** | ✅ | ✅ | ✅ | ✅ |
| **Event Handling** | ✅ | ✅ | ✅ | ✅ |
| **Maturity** | Mature | Mature | Stable | Stable |

## LiveSvelte

[LiveSvelte](https://github.com/woutdp/live_svelte) integrates Svelte with Phoenix LiveView, offering end-to-end reactivity.

### Key Features

- **Sigil DSL**: Use `~V` sigil to write Svelte code directly in LiveView templates
- **Server-Side Rendering**: Full SSR support with hydration
- **Slot Interoperability**: Pass LiveView content to Svelte components
- **Component Macro**: Auto-generate component functions from Svelte files
- **Preprocessing Support**: Built-in support for TypeScript, SCSS, etc.

### Example Usage

```elixir
# Component approach
<.svelte name="Counter" props={%{count: @count}} socket={@socket} />

# Sigil DSL approach
def render(assigns) do
  ~V"""
  <script>
    export let count = 0
    let localState = 1
    $: combined = count + localState
  </script>

  <p>Server count: {count}</p>
  <p>Local state: {localState}</p>
  <p>Combined: {combined}</p>

  <button phx-click="increment">Server increment</button>
  <button on:click={() => localState++}>Local increment</button>
  """
end
```

### When to Choose LiveSvelte

- You prefer Svelte's syntax and reactivity model
- You want to use Svelte as an alternative LiveView DSL
- You need advanced preprocessing (TypeScript, SCSS, etc.)
- You want the most mature LiveView + frontend framework integration
- You're building complex animations or transitions

### Considerations

- Custom build system (not standard esbuild)
- Larger learning curve if unfamiliar with Svelte
- "Secret state" caveat (client code visible to users)

## LiveReact

[LiveReact](https://github.com/mrdotb/live_react) brings React components into Phoenix LiveView applications.

### Key Features

- **SSR Support**: Server-side rendering with hydration
- **TypeScript Support**: Full TypeScript integration
- **Vite Integration**: Modern build tooling
- **Context Provider**: LiveReact context for accessing LiveView functions
- **Inner Block Slots**: Support for passing content to React components

### Example Usage

```elixir
<.react name="Counter" props={%{count: @count}} socket={@socket} />
```

```jsx
// Counter.jsx
import { useLiveReact } from 'live_react'

export default function Counter({ count }) {
  const { pushEvent } = useLiveReact()

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => pushEvent('increment')}>
        Increment
      </button>
    </div>
  )
}
```

### When to Choose LiveReact

- Your team has React expertise
- You want to reuse existing React components
- You need access to the vast React ecosystem
- You prefer JSX syntax
- You're migrating from a React application

### Considerations

- Newer library (less mature than LiveSvelte)
- React's larger bundle size
- More complex state management patterns in React

## LiveState

[LiveState](https://github.com/launchscout/live_state) takes a different approach, focusing on embeddable web applications and framework-agnostic state management.

### Key Features

- **Framework Agnostic**: Works with any frontend framework or vanilla JS
- **Embeddable Apps**: Designed for building widgets that embed in other sites
- **Channel-Based**: Uses Phoenix Channels for real-time communication
- **Event-Driven**: Client dispatches events, server manages state
- **JSON Patch Updates**: Efficient state synchronization

### Example Usage

```elixir
# Channel
defmodule MyApp.TodoChannel do
  use LiveState.Channel, web_module: MyAppWeb

  def init(_channel, _payload, _socket) do
    {:ok, %{todos: []}}
  end

  def handle_event("add_todo", todo, %{todos: todos}) do
    {:noreply, %{todos: [todo | todos]}}
  end
end
```

```javascript
// Client (any framework)
import LiveState from 'phx-live-state'

const liveState = new LiveState({
  url: 'ws://localhost:4000/socket',
  topic: 'todos:lobby'
})

liveState.addEventListener('state_change', (state) => {
  // Update UI with new state
})

liveState.dispatchEvent('add_todo', { title: 'New todo' })
```

### When to Choose LiveState

- You're building embeddable widgets for third-party sites
- You want framework flexibility (React, Vue, Svelte, vanilla JS)
- You need real-time updates across multiple clients
- You're building highly interactive components within existing apps
- You want minimal client-side complexity

### Considerations

- No SSR support
- More setup required for basic use cases
- Different mental model from traditional LiveView
- Best suited for specific use cases (embeddable apps)

## LiveVue

LiveVue provides seamless Vue.js integration with Phoenix LiveView.

### Key Features

- **End-to-End Reactivity**: Automatic prop updates from LiveView
- **Server-Side Rendering**: Optional SSR with configurable settings
- **Component Shortcuts**: Auto-generated component functions
- **Slot Support**: Pass LiveView content to Vue components
- **TypeScript Support**: Full TypeScript integration with Vite
- **Event Handling**: Multiple approaches for handling events

### Example Usage

```elixir
<.vue
  v-component="Counter"
 
  count={@count}
  v-on:increment={JS.push("inc")}
/>
```

```html
<!-- Counter.vue -->
<template>
  <div>
    <p>Count: {{ count }}</p>
    <button @click="$emit('increment')">Increment</button>
  </div>
</template>

<script setup>
defineProps(['count'])
defineEmits(['increment'])
</script>
```

### When to Choose LiveVue

- Your team has Vue.js expertise
- You want a balance between simplicity and power
- You prefer Vue's template syntax and reactivity system
- You need good TypeScript support with modern tooling
- You want comprehensive documentation and examples

## Decision Framework

### Choose **LiveVue** if:
- You're experienced with Vue.js
- You want excellent documentation and examples
- You need a balance of features and simplicity
- You prefer Vue's template syntax and composition API

### Choose **LiveSvelte** if:
- You love Svelte's syntax and reactivity model
- You want to use frontend framework as LiveView DSL
- You need the most mature integration
- You're building animation-heavy applications

### Choose **LiveReact** if:
- Your team is React-focused
- You want to reuse existing React components
- You need access to React's ecosystem
- You're migrating from a React application

### Choose **LiveState** if:
- You're building embeddable widgets
- You need framework flexibility
- You want real-time updates across clients
- You're building highly interactive components

### Stick with **Pure LiveView** if:
- Your app doesn't need complex client-side interactivity
- You want to minimize JavaScript complexity
- Your team is primarily backend-focused
- You're building traditional web applications

## Migration Considerations

### From LiveView to Any Integration

1. **Identify Components**: Determine which parts need client-side interactivity
2. **State Boundaries**: Decide what state lives on server vs client
3. **Event Patterns**: Plan how events flow between client and server
4. **Build Process**: Update your asset pipeline for the chosen framework

### Between Integrations

Most integrations follow similar patterns, making migration feasible:

1. **Component Structure**: All use similar prop-passing patterns
2. **Event Handling**: All support bidirectional event communication
3. **SSR**: Most support server-side rendering
4. **Build Tools**: May require build system changes

## Performance Considerations

### Bundle Size
- **LiveState**: Smallest (framework-agnostic)
- **LiveSvelte**: Small (Svelte compiles to minimal code)
- **LiveVue**: Medium (Vue runtime)
- **LiveReact**: Largest (React + ReactDOM)

### Runtime Performance
- **Svelte**: Fastest (compiled, no virtual DOM)
- **Vue**: Fast (optimized virtual DOM)
- **React**: Good (virtual DOM with optimizations)
- **LiveState**: Depends on chosen framework

### Server Load
All integrations have similar server load characteristics since they use LiveView's WebSocket connection for state synchronization.

## Community and Ecosystem

### LiveSvelte
- **Maturity**: Most mature integration
- **Community**: Active development and community
- **Documentation**: Comprehensive with examples

### LiveVue
- **Maturity**: Stable and well-documented
- **Community**: Growing community
- **Documentation**: Extensive guides and examples

### LiveReact
- **Maturity**: Recently reached v1.0
- **Community**: Active development
- **Documentation**: Good documentation

### LiveState
- **Maturity**: Stable for specific use cases
- **Community**: Focused on embeddable apps
- **Documentation**: Good for target use cases

For current GitHub star counts, check each project's repository directly.

## Conclusion

Each library serves different needs in the Phoenix LiveView ecosystem:

- **LiveVue** offers excellent Vue.js integration with comprehensive features
- **LiveSvelte** provides the most mature integration with unique DSL capabilities
- **LiveReact** brings React's ecosystem to LiveView applications
- **LiveState** enables embeddable applications and framework flexibility

Choose based on your team's expertise, project requirements, and long-term goals. All options provide solid foundations for building interactive web applications with Phoenix LiveView.

## Further Reading

- [LiveVue Documentation](https://hexdocs.pm/live_vue)
- [LiveSvelte Documentation](https://hexdocs.pm/live_svelte)
- [LiveReact Documentation](https://hexdocs.pm/live_react)
- [LiveState Documentation](https://hexdocs.pm/live_state)
- [Phoenix LiveView Documentation](https://hexdocs.pm/phoenix_live_view)
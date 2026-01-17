# Troubleshooting Guide

This guide helps you diagnose and fix common issues when working with LiveVue.

> #### Quick Start {: .tip}
>
> New to LiveVue? Start with [Getting Started](getting_started.md) for a working example, then check [Basic Usage](basic_usage.md) for common patterns.

## Component Issues

### Component Not Rendering

**Symptoms:**

- Empty div where component should be
- No errors in console
- Component works in isolation

**Possible Causes & Solutions:**

1. **Component name mismatch**

   ```elixir
   # ❌ File: Counter.vue, but using wrong name
   <.vue v-component="counter" />

   # ✅ Correct - case sensitive
   <.vue v-component="Counter" />
   ```

   Check browser console for errors.

2. **Component not found in resolution**

   ```javascript
   // Check your component resolution in assets/vue/index.js
   const components = {
     ...import.meta.glob("./**/*.vue", { eager: true }),
   }

   // Debug: log available components
   console.log("Available components:", Object.keys(components))
   ```

### Component Renders But Doesn't Update

**Symptoms:**

- Component shows initial state
- Props don't update when server state changes
- No reactivity

**Solutions:**

1. **Check prop names match**

   ```elixir
   # Server side
   <.vue user_name={@user.name} v-component="Profile" />
   ```

   ```html
   <!-- Client side - prop names must match exactly -->
   <script setup>
     const props = defineProps<{
       user_name: string  // Must match server prop name
     }>()
   </script>
   ```

2. **Verify assigns are updating**

   ```elixir
   # Add debug logging
   def handle_event("update", _params, socket) do
     IO.inspect(socket.assigns, label: "Before update")
     socket = assign(socket, :count, socket.assigns.count + 1)
     IO.inspect(socket.assigns, label: "After update")
     {:noreply, socket}
   end
   ```

3. **Use Vue.js devtools to inspect the component**

   Open Vue.js devtools in browser and inspect the component.
   Check if the component is receiving the correct props.
   Check if the component is re-rendering when the props change.

### LiveVue.Encoder Protocol Issues

**Symptoms:**

- `Protocol.UndefinedError` when passing structs as props
- Component doesn't render with custom struct props
- Error mentions "LiveVue.Encoder protocol must always be explicitly implemented"

**Solutions:**

1. **Implement the encoder protocol for your structs**

   ```elixir
   defmodule User do
     @derive LiveVue.Encoder
     defstruct [:name, :email, :age]
   end
   ```

2. **For third-party structs, use Protocol.derive/3**

   ```elixir
   # In your application.ex or relevant module
   Protocol.derive(LiveVue.Encoder, SomeLibrary.User, only: [:id, :name])
   ```

3. **Debug encoder issues**
   ```elixir
   # Test your encoder implementation
   iex> user = %User{name: "John", email: "john@example.com"}
   iex> LiveVue.Encoder.encode(user)
   %{name: "John", email: "john@example.com"}
   ```

For complete implementation details including field selection and custom implementations, see [Component Reference](component_reference.md#custom-structs-with-livevue-encoder).

**Common Causes:**

- Passing structs without implementing the encoder protocol
- Nested structs where some don't have the protocol implemented
- Third-party library structs that need protocol derivation

### TypeScript Errors

**Common Error: `Cannot find module 'live_vue'`**

```typescript
// Add to your env.d.ts or types.d.ts
declare module "live_vue" {
  export function useLiveVue(): any
  export function createLiveVue(config: any): any
  export function findComponent(components: any, name: string): any
  export function getHooks(app: any): any
}
```

**Error: `Property 'xxx' does not exist on type`**

```typescript
// Define proper interfaces
interface Props {
  count: number
  user: {
    id: number
    name: string
  }
}

const props = defineProps<Props>()
```

## Event Handling Issues

### Events Not Firing

**Symptoms:**

- Clicking buttons does nothing
- No events reach LiveView
- Console shows no errors

**Solutions:**

1. **Check event handler syntax**

   ```elixir
   # ❌ Wrong syntax
   <.vue v-on-click={JS.push("increment")} />

   # ✅ Correct syntax
   <.vue v-on:click={JS.push("increment")} />
   ```

2. **Verify event names match**

   ```html
   <!-- Vue component -->
   <button @click="$emit('increment', {amount: 1})">+1</button>
   ```

   ```elixir
   <!-- LiveView template -->
   <.vue v-on:increment={JS.push("inc")} />

   def handle_event("inc", %{"amount" => amount}, socket) do
     # Handle event
   end
   ```

3. **Check payload structure**
   ```elixir
   # Debug event payload
   def handle_event("save", params, socket) do
     IO.inspect(params, label: "Event params")
     {:noreply, socket}
   end
   ```

### Events Fire But Handler Not Called

**Check handler function exists:**

```elixir
# Make sure you have the handler defined
def handle_event("my_event", _params, socket) do
  {:noreply, socket}
end
```

**Verify event name spelling:**

```elixir
# Event names are case-sensitive
<.vue v-on:save-user={JS.push("save_user")} />  # save-user → save_user
```

## Build and Development Issues

### Vite Server Not Starting

**Error: `EADDRINUSE: address already in use`**

```bash
# Kill process using port 5173
lsof -ti:5173 | xargs kill -9

# Or use different port
npm run dev -- --port 5174
```

**Error: `Module not found`**

```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

### Build Failures

**TypeScript compilation errors:**

```bash
# Check TypeScript version compatibility
npm install typescript@5.5.4 vue-tsc@2.10.0
```

**Vite build errors:**

```bash
# Clear Vite cache
rm -rf node_modules/.vite
npm run build
```

### Hot Reload Not Working

1. **Check Vite configuration:**

   ```javascript
   // vite.config.js
   export default defineConfig({
     server: {
       host: "0.0.0.0", // Allow external connections
       port: 5173,
       hmr: true,
     },
   })
   ```

2. **Verify watcher configuration:**

   ```elixir
   # config/dev.exs
   config :my_app, MyAppWeb.Endpoint,
     watchers: [
       npm: ["--silent", "run", "dev", cd: Path.expand("../assets", __DIR__)]
     ]
   ```

3. **Understand HMR scope:**
   - **Vue files**: Hot Module Replacement works seamlessly - changes to `.vue` files are reflected instantly without page refresh
   - **Elixir files**: Changes to `.ex` and `.heex` files trigger a LiveView re-render via Phoenix's code reloading, not Vite HMR. This still provides fast feedback but works through LiveView's WebSocket connection rather than Vite's HMR

## SSR Issues

### SSR Not Working

**Check SSR configuration:**

```elixir
# config/dev.exs
config :live_vue,
  ssr_module: LiveVue.SSR.ViteJS,
  vite_host: "http://localhost:5173",
  ssr: true
```

For complete SSR configuration options, see [Configuration](configuration.md#server-side-rendering-ssr).

**Verify Node.js version:**

```bash
node --version  # Should be 19+
```

### SSR Errors in Production

**Check NodeJS supervisor:**

```elixir
# application.ex
children = [
  {NodeJS.Supervisor, [path: LiveVue.SSR.NodeJS.server_path(), pool_size: 4]},
  # ... other children
]
```

**Verify server bundle exists:**

```bash
ls priv/static/server.mjs  # Should exist after build
```

For production SSR setup details, see [Configuration](configuration.md#production-ssr-setup).

## Performance Issues

### Slow Initial Load

1. **Enable lazy loading:**

   ```javascript
   // assets/vue/index.js
   const components = {
     Counter: () => import("./Counter.vue"),
     Modal: () => import("./Modal.vue"),
   }
   ```

2. **Optimize bundle size:**
   ```bash
   # Analyze bundle
   npm run build -- --analyze
   ```

### Memory Leaks

**Clean up event listeners:**

```html
<script setup>
  import { onUnmounted } from "vue"
  import { useLiveVue } from "live_vue"

  const live = useLiveVue()

  const cleanup = live.handleEvent("data_update", handleUpdate)

  onUnmounted(() => {
    cleanup() // Important: clean up listeners
  })
</script>
```

**Clear timers and intervals:**

```html
<script setup>
  import { onUnmounted } from "vue"

  const interval = setInterval(() => {
    // Do something
  }, 1000)

  onUnmounted(() => {
    clearInterval(interval)
  })
</script>
```

## Debugging Techniques

### Enable Debug Mode

```javascript
// In browser console or app.js
window.liveVueDebug = true
```

### Component Inspection

1. **Use Vue DevTools browser extension**
2. **Add debug logging:**

   ```html
   <script setup>
     import { watch } from 'vue'

     const props = defineProps<{count: number}>()

     watch(() => props.count, (newVal, oldVal) => {
       console.log('Count changed:', oldVal, '→', newVal)
     })
   </script>
   ```

### Network Debugging

1. **Monitor WebSocket traffic in browser DevTools**
2. **Log LiveView events:**
   ```elixir
   def handle_event(event, params, socket) do
     IO.inspect({event, params}, label: "LiveView Event")
     # ... handle event
   end
   ```

## Common Error Messages

### `Cannot read property 'mount' of undefined`

**Cause:** Component resolution failed

**Solution:** Check component name and file path

```javascript
// Debug component resolution
// find component does it by default, you might need to do it if you override it
console.log("Resolving component:", componentName)
console.log("Available components:", Object.keys(components))
```

### `ReferenceError: process is not defined`

**Cause:** Node.js globals in browser code

**Solution:** Add to Vite config:

```javascript
// vite.config.js
export default defineConfig({
  define: {
    global: "globalThis",
    "process.env": {},
  },
})
```

### `Module "live_vue" has been externalized`

**Cause:** SSR configuration issue

**Solution:** Check Vite SSR config:

```javascript
// vite.config.js
export default defineConfig({
  ssr: {
    noExternal: ["live_vue"],
  },
})
```

## Getting Help

### Before Asking for Help

1. **Check browser console for errors**
2. **Verify all configuration steps** (see [Configuration](configuration.md))
3. **Test with minimal reproduction case**
4. **Create a fresh project with Igniter to verify the issue isn't in your configuration**

### Where to Get Help

1. **GitHub Issues**: For bugs and feature requests
2. **GitHub Discussions**: For questions and community help
3. **Elixir Forum**: For general Phoenix/Elixir questions
4. **Vue.js Discord**: For Vue-specific questions

### Creating Bug Reports

Include:

1. **LiveVue version**
2. **Phoenix/LiveView versions**
3. **Node.js version**
4. **Minimal reproduction case**
5. **Error messages and stack traces**
6. **Browser and OS information**

## Next Steps

- [Live Examples](https://livevue.skalecki.dev) - Working examples to compare against
- [FAQ](faq.md) for conceptual questions
- [Architecture](architecture.md) to understand how things work
- [Configuration](configuration.md) for advanced setup options
- [GitHub Issues](https://github.com/Valian/live_vue/issues) to report bugs

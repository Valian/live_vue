# Frequently Asked Questions

## General Questions

### Why LiveVue?

Phoenix LiveView makes it possible to create rich, interactive web apps without writing JS. However, when you need complex client-side functionality, you might end up writing lots of imperative, hard-to-maintain hooks.

LiveVue allows you to create hybrid apps where:
- Server maintains the session state
- Vue handles complex client-side interactions
- Both sides communicate seamlessly

Common use cases:
- Your hooks are starting to look like jQuery
- You have complex local state to manage
- You want to use the Vue ecosystem (transitions, graphs, etc.)
- You need advanced client-side features
- You simply like Vue 😉

### What's with the Name?

Yes, "LiveVue" sounds exactly like "LiveView" - we noticed slightly too late to change! Some helpful Reddit users pointed it out 😉

We suggest referring to it as "LiveVuejs" in speech to avoid confusion.

## Technical Details

### How Does LiveVue Work?

The implementation is straightforward:

1. **Rendering**: Phoenix [renders](https://github.com/Valian/live_vue/blob/main/lib/live_vue.ex) a `div` with:
   - Props as data attributes
   - Slots as child elements
   - Event handlers configured
   - SSR content (when enabled)

2. **Initialization**: The [LiveVue hook](https://github.com/Valian/live_vue/blob/main/assets/js/live_vue/hooks.js):
   - Mounts on element creation
   - Sets up event handlers
   - Injects the hook for `useLiveVue`
   - Mounts the Vue component

3. **Updates**:
   - Phoenix updates only changed data attributes
   - Hook updates component props accordingly

4. **Cleanup**:
   - Vue component unmounts on destroy
   - Garbage collection handles cleanup

Note: Hooks fire only after `app.js` loads, which may cause slight delays in initial render.

### What Optimizations Does LiveVue Use?

LiveVue implements several performance optimizations:

1. **Selective Updates**:
   - Only changed props/handlers/slots are sent to client
   - Achieved through careful `__changed__` assign modifications

2. **Efficient Props Handling**:
   ```elixir
   data-props={"#{@props |> Jason.encode()}"}
   ```
   String interpolation prevents sending `data-props=` on each update

3. **Coming Soon**:
   - Sending only updated props
   - Deep-diff of props (similar to LiveJson)

### Why is SSR Useful?

SSR (Server-Side Rendering) provides several benefits:

1. **Initial Render**: Components appear immediately, before JS loads
2. **SEO**: Search engines see complete content
3. **Performance**: Reduces client-side computation

Important notes:
- SSR runs only during "dead" renders (no socket)
- Not needed during live navigation
- Can be disabled per-component with `v-ssr={false}`

## Development

### How Do I Use TypeScript?

LiveVue provides full TypeScript support:

1. Use the example `tsconfig.json`
2. Check `example_project/assets/ts_config_example` for:
   - LiveVue entrypoint
   - Tailwind setup
   - Vite config

For `app.js`, since it's harder to convert directly:
```javascript
// Write your code in TypeScript
// app.ts
export const initApp = () => { /* ... */ }

// Import in app.js
import {initApp} from './app.ts'
initApp()
```

### Where Should I Put Vue Files?

Vue files in LiveVue are similar to HEEX templates. You have two main options:

1. **Default Location**: `assets/vue` directory
2. **Colocated**: Next to your LiveViews in `lib/my_app_web`

Colocating provides better DX by:
- Keeping related code together
- Making relationships clearer
- Simplifying maintenance

No configuration needed - just place `.vue` files in `lib/my_app_web` and reference them by name or path.

## Comparison with Other Solutions

### How Does LiveVue Compare to LiveSvelte?

Both serve similar purposes with similar implementations, but have key differences:

**Technical Differences**:
- Vue uses virtual DOM, Svelte doesn't
- Vue bundle is slightly larger due to runtime
- Performance is comparable

**Reactivity Approach**:
- Svelte: Compilation-based, concise but with [some limitations](https://thoughtspile.github.io/2023/04/22/svelte-state/)
- Vue: Proxy-based, more verbose but more predictable

**Future Developments**:
- Vue is working on [Vapor mode](https://github.com/vuejs/core-vapor) (no virtual DOM)
- Svelte 5 Runes will be similar to Vue `ref`

**Ecosystem**:
- Vue has a larger ecosystem
- More third-party components available
- Larger community

Choose based on:
- Your team's familiarity
- Ecosystem requirements
- Syntax preferences
- Bundle size concerns

## Additional Resources

- [GitHub Discussions](https://github.com/Valian/live_vue/discussions)
- [Example Project](https://github.com/Valian/live_vue/tree/main/example_project)
- [Vue Documentation](https://vuejs.org/)
- [Phoenix LiveView Documentation](https://hexdocs.pm/phoenix_live_view)
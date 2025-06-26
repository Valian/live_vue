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

For a deeper dive into the architecture, see [Architecture](architecture.html).

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

For complete SSR configuration, see [Configuration](configuration.html#server-side-rendering-ssr).

### Can I nest LiveVue components inside each other?

No, it is not possible to nest a `<.vue>` component rendered by LiveView inside another `<.vue>` component's slot.

**Why?**

This limitation exists because of how slots are handled. The content you place inside a component's slot in your `.heex` template is rendered into raw HTML on the server *before* being sent to the client. When the parent Vue component is mounted on the client, it receives this HTML as a simple string.

Since the nested component's HTML is just inert markup at that point, Phoenix LiveView's hooks (including the `VueHook` that powers LiveVue) cannot be attached to it, and the nested Vue component will never be initialized.

**Workarounds:**

1.  **Adjacent Components:** The simplest approach is to restructure your UI to use adjacent components instead of nested ones.

    ```elixir
    # Instead of this:
    <.Card v-socket={@socket}>
      <.UserProfile user={@user} v-socket={@socket} />
    </.Card>

    # Do this:
    <.Card v-socket={@socket} />
    <.UserProfile user={@user} v-socket={@socket} />
    ```

2.  **Standard Vue Components:** You can nest standard (non-LiveVue) Vue components inside a LiveVue component. These child components are defined entirely within the parent's Vue template and do not have a corresponding `<.vue>` tag in LiveView. They can receive props from their LiveVue parent and manage their own state as usual.

    ```html
    <!-- Parent: MyLiveVueComponent.vue -->
    <script setup>
    import StandardChild from './StandardChild.vue';
    defineProps(['someData']);
    </script>
    <template>
      <div>
        <h1>Data from LiveView: {{ someData }}</h1>
        <StandardChild :data-from-parent="someData" />
      </div>
    </template>
    ```

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

For complete TypeScript setup, see [Configuration](configuration.html#typescript-support).

### Where Should I Put Vue Files?

Vue files in LiveVue are similar to HEEX templates. You have two main options:

1. **Default Location**: `assets/vue` directory
2. **Colocated**: Next to your LiveViews in `lib/my_app_web`

Colocating provides better DX by:
- Keeping related code together
- Making relationships clearer
- Simplifying maintenance

No configuration needed - just place `.vue` files in `lib/my_app_web` and reference them by name or path.

For advanced component organization, see [Configuration](configuration.html#component-organization).

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

For a detailed comparison with other solutions, see [Comparison](comparison.html).

## Additional Resources

- [GitHub Discussions](https://github.com/Valian/live_vue/discussions)
- [Example Project](https://github.com/Valian/live_vue/tree/main/example_project)
- [Vue Documentation](https://vuejs.org/)
- [Phoenix LiveView Documentation](https://hexdocs.pm/phoenix_live_view)
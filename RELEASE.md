After over four months of release candidates and community feedback, LiveVue 1.0 is ready. This release brings a complete rewrite of the developer experience—from a simplified no-build-step architecture to powerful new composables for forms, file uploads, and real-time communication. Whether you're building interactive dashboards, complex forms with server-side validation, or real-time collaborative features, LiveVue now provides first-class tooling to make Vue and Phoenix LiveView work together seamlessly.

### Breaking Changes

- **Removed `shared_props` configuration** - This feature had a fundamental flaw: LiveView only re-renders components when explicitly-passed assigns change. Since shared props were injected at render time (not in the template), changes to shared props would not trigger component re-renders. Pass props explicitly instead: `<.vue flash={@flash} user={@current_user} ... />`

### Features

- **`useLiveForm` composable** - Comprehensive form handling with server-side validation, nested objects, and dynamic arrays
- **`useEventReply` composable** - Reactive bi-directional LiveView event communication with server responses
- **`useLiveConnection` composable** - Reactive WebSocket connectivity monitoring for connection status indicators and offline handling
- **Phoenix Streams support** - Full integration with LiveView streams for efficient list rendering
- **Phoenix AsyncResult support** - `assign_async` works correctly out of the box when passed as a prop
- **Igniter-based installer** - Run `mix igniter.install live_vue` for automated project setup

### Improvements

- **No JavaScript build step** - Package exports TypeScript source files directly; Vite handles transpilation during your app's build
- **Flattened assets structure** - Simpler `assets/` directory layout
- **Improved component lookup** - More flexible matching for `findComponent`
- **LazyHTML for testing** - Replaced Floki with LazyHTML for lighter testing utilities
- **Elixir 1.19 and OTP 28 support**
- **VS Code extension** - Syntax highlighting for Vue sigils (`~VUE`)
- **AGENTS.md integration** - Installation appends LiveVue usage rules for AI-assisted development

### Bug Fixes

- Fixed slots containing non-ASCII characters not displaying correctly
- Fixed diff values not always being correctly encoded
- Fixed removal of embedded items in forms
- Fixed streams handling when `enable_props_diff: false`
- Fixed stream items inserted at index 0 appearing in wrong order
- Fixed SSR bundle overwriting client bundle files
- Fixed encoder compilation without Ecto dependency
- Fixed installer skipping html_helpers modification for LiveVue-prefixed projects
- Exported `useField` and `useArrayField` from `useLiveForm.ts`

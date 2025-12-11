# LiveVue Library Development

Vue.js + Phoenix LiveView integration library. Version 1.0.0-rc.4.

## Quick Reference

```bash
# Tests
mix test                          # Elixir tests
npm test                          # Vitest (assets/js/live_vue/*.test.ts)
npm run e2e:test                  # Playwright E2E (test/e2e/)

# Development (mix assets.watch runs in background automatically)
cd example_project && mix phx.server   # Test at localhost:4000

# Build & Setup
mix setup                         # First-time setup
mix assets.build                  # Build assets (usually automatic)
```

## Project Structure

```
lib/
├── live_vue.ex              # Main module, ~VUE sigil
├── live_vue/components.ex   # <.vue> component, props handling
├── live_vue/encoder.ex      # JSON encoding for Vue props
├── live_vue/slots.ex        # Slot interoperability
└── live_vue/ssr/            # SSR: NodeJS and ViteJS modes
assets/js/live_vue/
├── index.ts                 # Main entry, getHooks()
├── hooks.ts                 # Phoenix LiveView hooks
├── use.ts                   # Vue composables (useLiveEvent, etc.)
├── useLiveForm.ts           # Form handling with Ecto changesets
├── jsonPatch.ts             # Efficient prop diffing
└── vitePlugin.ts            # Vite plugin for component discovery
example_project/             # Test app using library directly
test/e2e/                    # Playwright tests with Phoenix server
```

## Key Patterns

### Component Usage (Elixir)
```elixir
# In LiveView template
<.vue count={@count} v-component="Counter" v-socket={@socket} />

# Or with ~VUE sigil
~VUE"""
<Counter :count="count" />
"""
```

### Vue Composables (TypeScript)
- `useLive()` - Access to `$live.pushEvent()`, props
- `useLiveEvent(name, handler)` - LiveView event subscription
- `useLiveNavigation()` - `patch()` and `navigate()` helpers
- `useLiveForm(formName)` - Server-side validation with Ecto
- `useLiveUpload(uploadName)` - File upload integration

### SSR Modes
- `LiveVue.SSR.NodeJS` - Node.js subprocess (default)
- `LiveVue.SSR.ViteJS` - HTTP to Vite dev server (dev mode)

## E2E Testing

Vue components in `test/e2e/vue/`, discovered via `import.meta.glob("../vue/**/*.vue")`.

Key utilities in `test/e2e/utils.js`:
- `syncLV(page)` - Wait for LiveView connection
- `evalLV(page, code)` - Execute Elixir in LiveView process

## Conventions

Commit format: `type: description` (feat/fix/docs/test/refactor/chore)

## Release Process

`package.json` exports point to TypeScript source files (`assets/js/live_vue/*.ts`) during development. This allows installing directly from GitHub without a build step, since Vite handles TS transpilation.

For hex.pm releases, `mix release.{patch,minor,major}` automatically:
1. Builds assets (`npm run build` → `priv/static/*.js`)
2. Swaps `package.json` exports to compiled JS paths
3. Runs expublish (commits, tags)
4. Restores `package.json` to TS paths

## Notes

- This is a library - use `example_project/` for manual testing
- Changes to lib/ are immediately reflected in example_project/
- CI: Elixir (.github/workflows/elixir.yml), Frontend (.github/workflows/frontend.yml)

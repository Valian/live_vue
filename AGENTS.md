# LiveVue Library Development

Vue.js + Phoenix LiveView integration library. Version 1.0.0.

## Quick Reference

```bash
# Tests
mix test                          # Elixir tests
npm test                          # Vitest (assets/*.test.ts)
mix e2e.test                      # Playwright E2E (e2e_pw/, server in test/e2e/)

# Setup
mix setup                         # First-time setup (deps + npm install)
```

## Project Structure

```
lib/
├── live_vue.ex              # Main module, ~VUE sigil
├── live_vue/components.ex   # <.vue> component, props handling
├── live_vue/encoder.ex      # JSON encoding for Vue props
├── live_vue/slots.ex        # Slot interoperability
└── live_vue/ssr/            # SSR: QuickBEAM, NodeJS, and ViteJS modes
assets/
├── index.ts                 # Main entry, getHooks()
├── hooks.ts                 # Phoenix LiveView hooks
├── use.ts                   # Vue composables (useLiveEvent, etc.)
├── useLiveForm.ts           # Form handling with Ecto changesets
├── jsonPatch.ts             # Efficient prop diffing
└── vitePlugin.js            # Vite plugin for component discovery
test/e2e/                    # Phoenix server and features for the E2E tests
e2e_pw/                      # Playwright E2E tests (ExUnit, playwright_ex)
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
- `useLiveVue()` - Access to `$live.pushEvent()`, props
- `useLiveEvent(name, handler)` - LiveView event subscription
- `useLiveNavigation()` - `patch()` and `navigate()` helpers
- `useLiveForm(formName)` - Server-side validation with Ecto
- `useLiveUpload(uploadName)` - File upload integration

### SSR Modes
- `LiveVue.SSR.QuickBEAM` - embedded BEAM runtime (production default)
- `LiveVue.SSR.NodeJS` - Node.js subprocess
- `LiveVue.SSR.ViteJS` - HTTP to Vite dev server (dev mode)

## E2E Testing

Colocated feature structure in `test/e2e/features/`:

```
test/e2e/features/
├── basic/            # Each feature is a directory
│   ├── live.ex       # LiveView module
│   ├── counter.vue   # Vue component(s)
│   └── ...
├── form/
├── stream/
└── ...
```

To add a new E2E test:
1. Create `test/e2e/features/my-feature/`
2. Add `live.ex` (LiveView) and `*.vue` (components)
3. Add route to `test/e2e/server.exs` router
4. Add the test to `e2e_pw/` (`use LiveVue.E2E.Case`)

Key utilities in `e2e_pw/support/utils.ex`:
- `sync_lv(page)` - Wait for LiveView connection
- `eval_lv(page, code)` - Execute Elixir in LiveView process

## Conventions

Commit format: `type: description` (feat/fix/docs/test/refactor/chore)

## Release Process

No JS build step required. `package.json` exports point directly to TypeScript source files (`assets/*.ts`). Vite handles TS transpilation when consumers bundle their app.

For hex.pm releases, `mix release.{patch,minor,major}` runs easy_publish (bumps version, updates CHANGELOG, commits, tags, pushes, publishes to Hex).

## Notes

- This is a library - use E2E tests (`mix e2e.test`) for testing
- CI: Elixir (.github/workflows/elixir.yml), Frontend (.github/workflows/frontend.yml)

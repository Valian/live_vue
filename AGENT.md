# LiveVue Development Guide

## Commands
- **Run single test**: `mix test path/to/test_file.exs:line_number` or `mix test path/to/test_file.exs`
- **Test with coverage**: `mix coveralls.html`
- **Watch tests**: `mix test.watch`
- **Build TypeScript**: `mix assets.build` or `npm run build`
- **Watch assets**: `mix assets.watch` or `npm run dev`
- **Format code**: `mix format` (Elixir) and `npm run format` (JS/TS)
- **Setup project**: `mix setup` (gets deps and installs npm packages)

## Architecture
- **Main library**: `lib/live_vue/` - Core LiveVue functionality for Phoenix LiveView + Vue integration
- **TypeScript**: `assets/` - Vue client-side code, compiled to `priv/static/`
- **Example project**: `example_project/` - Test/demo Phoenix app
- **Guides**: `guides/` - Documentation markdown files
- **SSR support**: Via ViteJS or NodeJS for server-side rendering

## Code Style
- **Line length**: 120 characters (`.formatter.exs`)
- **Imports**: Follow Phoenix conventions, `import Phoenix.Component` for LiveView
- **Testing**: Use `ExUnit.Case`, import `Phoenix.LiveViewTest` and `LiveVue` for Vue component tests
- **TypeScript**: Configured via `tsconfig.*.json`, built to `priv/static/`
- **Formatting**: Auto-format with `mix format` and `npm run format`

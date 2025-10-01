# Installation

LiveVue replaces `esbuild` with [Vite](https://vitejs.dev/) for both client side code and SSR to achieve an amazing development experience.

## Why Vite?

- Vite provides a best-in-class Hot-Reload functionality and offers [many benefits](https://vitejs.dev/guide/why#why-vite)
- `esbuild` package doesn't support plugins, so we would need to setup a custom build process anyway
- In production, we'll use [elixir-nodejs](https://github.com/revelrylabs/elixir-nodejs) for SSR

If you don't need SSR, you can easily disable it with one line of configuration.

## Prerequisites

- Node.js installed (version 19 or later recommended)
- Elixir 1.13+
- **Phoenix 1.8+** (required for Igniter installer)
- [Igniter](https://hexdocs.pm/igniter/) installed (see below)

## Quick Start (Recommended)

### Installing Igniter

First, install the Igniter archive:

```bash
mix archive.install hex igniter_new
```

### New Project

Create a new Phoenix project with LiveVue pre-installed:

```bash
mix igniter.new my_app --with phx.new --install live_vue
```

This command will:
- Create a new Phoenix project using `phx.new`
- Install and configure LiveVue automatically
- Set up Vite, Vue, TypeScript, and all necessary files
- Create a working Vue demo component

### Existing Project

To add LiveVue to an existing Phoenix 1.8+ project:

```bash
mix igniter.install live_vue@1.0.0-rc.3
```

This will automatically configure your project with all necessary LiveVue setup.

> #### Important Limitations {: .warning}
>
> - **Phoenix 1.8+ required**: The Igniter installer depends on `phoenix_vite` and modern Phoenix features that are only available in Phoenix 1.8+
> - **Pre-Igniter LiveVue upgrade not supported**: If you have an existing LiveVue installation from before the Igniter installer was introduced, upgrading via `mix igniter.install live_vue@1.0.0-rc.3` is not supported due to significant changes in the installation process. On the other hand, you should be able to bump version of LiveVue in your `mix.exs` file and everything should still work.
> - **LiveVue itself works with Phoenix 1.7**: While the automated installer requires Phoenix 1.8+, the LiveVue library itself is compatible with Phoenix 1.7 if installed manually

## Manual Installation

> #### Outdated Manual Instructions {: .warning}
>
> Manual installation instructions are currently outdated and don't work with current versions of dependencies (Tailwind, Phoenix, etc).
>
> If you need manual installation for LiveVue <= 0.7, see the [v0.7 documentation](https://hexdocs.pm/live_vue/0.7.3/installation.html).
>
> **We strongly recommend using the Igniter installation above.**

The manual installation process involves many complex steps including:
- Configuring Vite and Vue dependencies
- Setting up TypeScript and PostCSS
- Updating Phoenix configuration files
- Configuring Tailwind for Vue files
- Setting up SSR for production
- And many more manual steps...

For the current version, please use the Igniter installation above.

## Next Steps

Now that you have LiveVue installed, check out our [Getting Started Guide](getting_started.md) to create your first Vue component!
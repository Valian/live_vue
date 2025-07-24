# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- %% CHANGELOG_ENTRIES %% -->

## 0.6.1 - 2025-07-24

### Fixes 🐛

- correctly encode props in SSR mode
- correctly handle diffs for nil values in props
- added package version to the package.json

## 0.6.0 - 2025-07-22

### ✨ Features and Improvements

*   **JSON Patch Diffs for Props**: LiveVue now uses JSON Patch operations to send only the minimal differences when props change, dramatically reducing WebSocket payload sizes. Instead of sending entire prop objects, only the specific fields that changed are transmitted using RFC 6902 JSON Patch format. This optimization works seamlessly with complex nested structures, lists, and custom structs through the `LiveVue.Encoder` protocol. It's possible to skip diffs by setting `v-diff` to `false` on the component or by setting `config :live_vue, enable_props_diff: false` in your config. ([#60](https://github.com/Valian/live_vue/pull/60))
*   **New `useLiveNavigation` Composable**: A new `useLiveNavigation` composable has been added for programmatic navigation, mirroring the functionality of `live_patch` and `live_redirect`. ([#59](https://github.com/Valian/live_vue/pull/59)).
*   **New `useLiveEvent` Composable**: A new `useLiveEvent` composable has been added to simplify listening to server-pushed events. It automatically manages event listener lifecycle, reducing boilerplate and preventing memory leaks ([#58](https://github.com/Valian/live_vue/pull/58)).
*   **New `Link` Component**: A new `<Link>` Vue component has been added to simplify `live_patch` and `live_redirect` navigation within your Vue components. ([#47](https://github.com/Valian/live_vue/pull/47)).
*   **TypeScript by Default**: The client-side entrypoint at `assets/vue/index.ts` is now a TypeScript file by default, improving type safety and the development experience out of the box.
*   **`$live` Template Property**: The LiveView hook instance is now automatically available in all Vue templates as the `$live` property, providing a convenient alternative to `useLiveVue()`. The property is now also fully typed, providing autocompletion and type checking in your editor. ([#56](https://github.com/Valian/live_vue/pull/56)).
*   **Documentation Overhaul**: The documentation has been completely rewritten and expanded. It now includes comprehensive guides on architecture, basic and advanced usage, a full client-side API reference, a component reference, and much more. ([#49](https://github.com/Valian/live_vue/pull/49))
*   **Testing Utilities**: The new `LiveVue.Test` module provides helpers to inspect Vue component configuration (props, slots, event handlers) within your LiveView tests, making it easier to write assertions. ([#46](https://github.com/Valian/live_vue/pull/46))
*   **GitHub CI**: A new GitHub Actions workflow has been added to run tests automatically.

### ⬆️ Migration Guide

This version transitions the default client-side setup to TypeScript and renames ~V sigil to ~VUE. If you have an existing `assets/vue/index.js`, follow these steps to upgrade:

1.  **Rename and replace `index.js`**:
    *   Delete your existing `assets/vue/index.js`.
    *   Create a new file at `assets/vue/index.ts` with the following content:

    ```typescript
    // polyfill recommended by Vite https://vitejs.dev/config/build-options#build-modulepreload
    import "vite/modulepreload-polyfill"
    import { Component, h } from "vue"
    import { createLiveVue, findComponent, type LiveHook, type ComponentMap } from "live_vue"

    // needed to make $live available in the Vue component
    declare module "vue" {
      interface ComponentCustomProperties {
        $live: LiveHook
      }
    }

    export default createLiveVue({
      // name will be passed as-is in v-component of the .vue HEEX component
      resolve: name => {
        // we're importing from ../../lib to allow collocating Vue files with LiveView files
        // eager: true disables lazy loading - all these components will be part of the app.js bundle
        // more: https://vite.dev/guide/features.html#glob-import
        const components = {
          ...import.meta.glob("./**/*.vue", { eager: true }),
          ...import.meta.glob("../../lib/**/*.vue", { eager: true }),
        } as ComponentMap

        // finds component by name or path suffix and gives a nice error message.
        // `path/to/component/index.vue` can be found as `path/to/component` or simply `component`
        // `path/to/Component.vue` can be found as `path/to/Component` or simply `Component`
        return findComponent(components as ComponentMap, name)
      },
      // it's a default implementation of creating and mounting vue app, you can easily extend it to add your own plugins, directives etc.
      setup: ({ createApp, component, props, slots, plugin, el }) => {
        const app = createApp({ render: () => h(component as Component, props, slots) })
        app.use(plugin)
        // add your own plugins here
        // app.use(pinia)
        app.mount(el)
        return app
      },
    })
    ```

2.  **Update `tsconfig.json`**:
    Add `vue/index.ts` to the `include` array in your `assets/tsconfig.json` file. The final result should look similar to this:

    ```json
    {
      "compilerOptions": {
        // ...
      },
      "include": ["js/**/*.ts", "js/**/*.js", "js/**/*.tsx", "vue/**/*.vue", "vue/index.ts"]
    }
    ```

### 🐛 Bug Fixes

*   **SSR Attribute Rendering**: Fixed a bug where the `data-ssr` attribute was not being rendered correctly as a boolean `true` or `false` in the final HTML.

### Housekeeping

*   **Optional Floki Dependency**: `floki` is now an optional dependency, only required if you use the new testing utilities.
*   **Dependency Updates**: NPM dependencies have been updated to address security vulnerabilities.
*   **Dropped Elixir 1.12 Support**: Support for Elixir 1.12 has been removed to align with Phoenix LiveView's supported versions.


## 0.5.7 - 2024-12-04

### Fixes

- Fix the `useLiveVue` hook typings to show all available functions and properties.


## 0.5.6 - 2024-11-27

### Improvements

- Much better typing for the library [#41](https://github.com/Valian/live_vue/pull/41). Big thanks to [@francois-codes](https://github.com/francois-codes) for the contribution!
- Added `worker` option to `vite.config.js`, and added instruction how to deal with typescript error [#45](https://github.com/Valian/live_vue/pull/45)


## 0.5.5 - 2024-11-14

### Fixes

- Slots are now rendered correctly in SSR [#39](https://github.com/Valian/live_vue/pull/39)


## 0.5.4 - 2024-11-13

### Fixed

- added type: module to package.json in live_vue to fix the older nodejs module resolution issue [#36](https://github.com/Valian/live_vue/issues/36)


## 0.5.3 - 2024-11-12

### Fixed

- Added explicit extensions to all JS imports. It should fix some issues with module resulution. [#36](https://github.com/Valian/live_vue/issues/36)


## 0.5.2 - 2024-10-08

### Changed

- Added hint to pass `--silent` flag to `npm` watcher in `INSTALLATION.md`. It prevents `npm` from printing executed command which is not useful and makes output messy.

```elixir
config :my_app, MyAppWeb.Endpoint,
  # ...
  watchers: [
    npm: ["--silent", "run", "dev", cd: Path.expand("../assets", __DIR__)]
  ]
```


## 0.5.1 - 2024-10-08

### Fixed

- Fixed a bug where the server was not preloading the correct assets for the Vue components. It happened because CursorAI "skipped" important part of the code when migrating to the TypeScript 😅


## 0.5.0 - 2024-10-08

### Changed

- Migrated the project to TypeScript 💜 [#32](https://github.com/Valian/live_vue/pull/32)
- Added `createLiveVue` entrypoint to make it easier to customize Vue app initialization


### Deprecations

- `assets/vue/index.js` should export app created by `createLiveVue()`, not just available components. See migration below.


### Migration

In `assets/js/app.js`, instead of:

```js
export default {
  ...import.meta.glob("./**/*.vue", { eager: true }),
  ...import.meta.glob("../../lib/**/*.vue", { eager: true }),
}
```

use:
```js
// polyfill recommended by Vite https://vitejs.dev/config/build-options#build-modulepreload
import "vite/modulepreload-polyfill"
import { h } from "vue"
import { createLiveVue, findComponent } from "live_vue"

export default createLiveVue({
  resolve: name => {
    const components = {
      ...import.meta.glob("./**/*.vue", { eager: true }),
      ...import.meta.glob("../../lib/**/*.vue", { eager: true }),
    }

    // finds component by name or path suffix and gives a nice error message.
    // `path/to/component/index.vue` can be found as `path/to/component` or simply `component`
    // `path/to/Component.vue` can be found as `path/to/Component` or simply `Component`
    return findComponent(components, name)
  },
  setup: ({ createApp, component, props, slots, plugin, el }) => {
    const app = createApp({ render: () => h(component, props, slots) })
    app.use(plugin)
    app.mount(el)
    return app
  },
})
```

then, in `assets/js/app.js`, instead of:

```js
import components from "./vue"
```

simply do

```js
import { getHooks } from "live_vue"
import liveVueApp from "./vue"
// ...

const hooks = { ...getHooks(liveVueApp) }
```

If you had any custom initialization code, you have to move it to `createLiveVue().setup()` function.


### Fixed

- Nicely formatted JS error stracktraces during SSR [commit](https://github.com/Valian/live_vue/commit/10f672bce4104a38523905c52c4879083e4bc6db)
- Previously `initializeVueApp` was not working in SSR mode, since it was declared in app.js which couldn't be imported by server bundle. Now it's in a separate file as `createLiveVue().setup()` and can be imported by both client and server bundles.


## 0.4.1 - 2024-08-30

### Changed

-   Improved `pathToFullPathAndFilename` to work with `index.vue` files. Now `../ComponentName/index.vue` can be referenced as `ComponentName` [#23](https://github.com/Valian/live_vue/pull/23)


## 0.4.0 - 2024-06-12

### New feature

-   Support for custom Vue instance initialization [#13](https://github.com/Valian/live_vue/pull/13) by @morfert


## 0.3.9 - 2024-06-07




## 0.3.8 - 2024-06-01

### Fixed

-   Invalid live_vue import in copied package.json (`file:../..` -> `file:../deps/live_vue`)
-   Changed `useLiveVue` inject key from `Symbol()` to `_live_vue` string, so it's working if Vite does a reload and Symbol is re-evaluated.

### Added

-   Added live_vue, phoenix, phoenix_html and phonenix_live_vue to vite `optimizeDeps.include` config options. It should pre-bundle these packages in development, making it consistent with packages imported from node_modules and improve DX.
-   Added initial typescript definitions. Apparently it's enough to name them `<filename>.d.mts`, so I've created them both for `index.mjs` and `server.mjs`


## 0.3.7 - 2024-05-26

### Changed

-   Added a Mix.Task to make JS file setup more straightforward and cross-platform [#11](https://github.com/Valian/live_vue/pull/11). Contribution by @morfert 🔥
-   Installation instruction was moved to the separate file
-   Package.json was added to files automatically copied from live_vue when using `mix live_vue.setup`

### Fixed

-   Removed `build: {modulePreload: { polyfill: false }}` from vite.config.js as it made it impossible to use `vite/modulepreload-polyfill`. To migrate: please remove that line from yours vite.config.js. Fixed [#12](https://github.com/Valian/live_vue/issues/12)


## 0.3.6 - 2024-05-24

### Fixed

-   Fixed missing import in loadManifest
-   Added `import "vite/modulepreload-polyfill";` to `assets/vue/index.js`. To migrate, add that line to the top. It adds polyfill for module preload, required for some browsers. More here: https://vitejs.dev/config/build-options#build-modulepreload


## 0.3.5 - 2024-05-24

### Changed

-   Removed `body-parser` dependency from `live_vue`. Should fix [#9](https://github.com/Valian/live_vue/issues/9)


## 0.3.4 - 2024-05-22

### Fixed

-   Props are correctly updated when being arrays of structs


## 0.3.3 - 2024-05-22

### Fixed

-   Javascript imports were mixed - vitePlugin.js was using CJS, rest was using ESM. Now it's explicit by adding ".mjs" extension.
-   Removed `:attr` declarations for `<.vue>` component to avoid warnings related to unexpected props being passed to `:rest` attribute [#8](https://github.com/Valian/live_vue/pull/8)


## 0.3.2 - 2024-05-19

### Fixed

-   Hot reload of CSS when updating Elixir files

## 0.3.1 - 2024-05-17

### Changed

-   Simplified `assets/vue/index.js` file - mapping filenames to keys is done by the library. Previous version should still work.

## 0.3.0 - 2024-05-17

### CHANGED

-   removed esbuild from live_vue, `package.json` points directly to `assets/js/live_vue`
-   added support to lazy loading components. See more in README. To migrate, ensure all steps from installation are up-to-date.

## 0.2.0 - 2024-05-17

QoL release

### Added

-   `@` added to Vite & typescript paths. To migrate, see `assets/copy/tsconfig.json` and `assets/copy/vite.config.js`
-   Added Vite types to tsconfig.json to support special imports, eg. svg. To migrate, add `"types": ["vite/client"]`.
-   Added possibility to colocate Vue files in `lib` directory. To migrate, copy `assets/copy/vue/index.js` to your project.

### Changed

-   Adjusted files hierarchy to match module names
-   Publishing with expublish

## [0.1.0] - 2024-05-15

### Initial release

-   Start of the project
-   End-To-End Reactivity with LiveView
-   Server-Side Rendered (SSR) Vue
-   Tailwind Support
-   Dead View Support
-   Vite support

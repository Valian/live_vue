# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- %% CHANGELOG_ENTRIES %% -->

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

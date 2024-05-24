# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- %% CHANGELOG_ENTRIES %% -->

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

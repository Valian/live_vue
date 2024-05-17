# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- %% CHANGELOG_ENTRIES %% -->

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

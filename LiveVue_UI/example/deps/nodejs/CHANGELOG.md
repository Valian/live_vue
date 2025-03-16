# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [3.1.2]

### Changed
- fix #90 terminal corruption when running inside an iEx session

### Contributors
- @francois-codes for the fix
- @mrdotb and @Valian for contributing to the discussion


## [3.1.1]

### Changed
- add a minimal `package.json` alongside `server.js` to work with projects that specify a module type other than `commonjs`

### Contributors
- @Valian


## [3.1.0]

### Changed
- add support for JS that imports ESM modules (#84)

### Contributors
- @Valian


## [3.0.0]

This version is mainly a maintenance release to get all of the tooling and required language versions up-to-date so we can begin merging more substantive fixes and iterating on functionality.

### Changed
- update language support minimums to Elixir 1.12, OTP 24, and Node 18
- format code with the latest `mix format` settings
- replace Travis CI with GitHub Actions for CI/CD
- add `.dependabot.yml` config file
- remove coverage reporting
- upgrade dependencies

### Fixed
- fixed test error due to JS TypeError format change

### Contributors
- @quentin-bettoum


## [2.0.0]

### Added
- support for GenServer name registration to support multiple supervisors

### Changed
- updated Elixir requirements to 1.7

### Fixed
- `Task.async` and `Task.await` caller leaks with timeouts and worker crash
- `console.*` calls in JavaScript code no longer causes workers to crash

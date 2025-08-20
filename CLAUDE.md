# LiveVue Library Development with Claude Code

This is the LiveVue library itself - an Elixir library that integrates Vue.js with Phoenix LiveView.

## Project Structure

- **lib/**: Core LiveVue library code (components, SSR, encoding, etc.)
- **assets/**: Frontend TypeScript/JavaScript assets that get packaged with the library
- **guides/**: Comprehensive documentation for LiveVue users
- **example_project/**: Phoenix project using LiveVue directly from parent directory for testing

## Development Commands

### Testing

#### Elixir Tests
```bash
mix test
# Run a specific test file
mix test test/live_vue_test.exs
# Run a specific test in a specific file
mix test test/live_vue_test.exs:123
```
Runs the library test suite.

#### Frontend Tests
```bash
npm test
# or via Mix alias:
mix assets.test
```
Runs the frontend test suite using Vitest. Tests are located in `assets/js/live_vue/*.test.ts`.

Additional test commands:
- `npm run test:watch` - Run tests in watch mode
- `npm run test:ui` - Run tests with interactive UI

#### End-to-End Tests
```bash
npm run e2e:test
```
Runs Playwright E2E tests located in `test/e2e/`. These tests use a real Phoenix server with LiveView and Vue components.

Additional E2E commands:
- `npm run e2e:install` - Install E2E test dependencies
- `npm run e2e:test:headed` - Run tests with browser UI visible
- `npm run e2e:test:debug` - Run tests in debug mode with Playwright inspector
- `npm run e2e:server` - Start E2E test server manually (runs on port 4004)

### Asset Watching (Development)
```bash
mix assets.watch
```
This command watches for changes in assets and rebuilds automatically. Essential for development workflow. Developer said it's always running in the background, you don't need to run it manually.

### Build Assets
```bash
mix assets.build
```
Builds all assets for the library. Not needed most of the time, as assets are built automatically in the background.

### Setup
```bash
mix setup
```
Sets up dependencies and builds assets for the first time.

## Testing Changes

### Example Project
```bash
cd example_project
mix phx.server
```
Visit http://localhost:4000 to test LiveVue features. Changes to the parent library are reflected immediately.

## Library Structure

### Core Modules
- **LiveVue.Components**: Component helpers and macros
- **LiveVue.SSR**: Server-side rendering (Node.js and Vite.js)
- **LiveVue.Encoder**: JSON encoding for Vue props
- **LiveVue.Diff**: Efficient prop diffing for WebSocket updates

### Key Technologies
- Elixir/Phoenix for server-side integration
- Vue 3 with TypeScript for client-side components
- Vite for fast development and building
- Server-side rendering support
- JSON patch diffing for efficient updates
- Vitest for frontend testing with TypeScript support

## CI/CD

The project uses two separate GitHub Actions workflows:

- **Elixir CI** (`.github/workflows/elixir.yml`): Tests Elixir code across multiple Elixir/OTP versions
- **Frontend CI** (`.github/workflows/frontend.yml`): Tests frontend TypeScript code across Node.js versions 20, 22, and 24

Both workflows run on pushes to main and pull requests.

## Commit Conventions

This project follows lightweight conventional commits suitable for an Elixir OSS library:

### Format
```
<type>: <description>

- Bullet point details
- Additional changes
- Context or reasoning
```

### Types
- `feat:` - New features or enhancements
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Adding or updating tests
- `refactor:` - Code refactoring without behavior changes
- `chore:` - Maintenance tasks, dependency updates

### Examples
```
feat: add comprehensive frontend testing suite

- Add Vitest testing framework with jsdom environment
- Create comprehensive test suite for jsonPatch.ts
- Add separate GitHub Actions workflow for frontend testing
```

```
fix: handle nil values in prop diffing

- Correctly encode nil values in SSR mode
- Add test cases for nil prop scenarios
```

## Task Delegation Guidelines

When working with Claude Code, use subagents strategically to parallelize execution and optimize context usage:

### When to Use Subagents
- **Clear, well-defined tasks** that can be described in detail and delegated
- **Research tasks** like searching for specific code patterns, functions, or implementations
- **File exploration** when you need to understand multiple files or codebases
- **Independent subtasks** that don't require back-and-forth communication
- **Context-heavy operations** to preserve main context for coordination

### Examples
- "Search for all error handling patterns in the codebase"
- "Find and analyze the implementation of component registration"
- "Research how Vue components are integrated with LiveView"
- "Locate and examine all test files for a specific module"

### Best Practices
- Provide detailed, specific instructions to subagents
- Use subagents for exploration before making changes
- Delegate research while keeping implementation coordination in main context
- Batch similar research tasks to single subagents when possible

## E2E Testing Architecture

### Test Structure
- **Playwright Configuration**: `test/e2e/playwright.config.js` - Configured for Chromium with trace and screenshot capture on failure
- **Test Server**: Standalone Phoenix application (port 4004) with LiveView and Vue integration
- **Test Utilities**: Custom utilities in `utils.js` for LiveView/Vue synchronization and testing
- **Test Cases**: Located in `test/e2e/tests/` directory

### Key Testing Components

#### Test Server (`test/e2e/test_helper.exs`)
- **LiveVue.E2E.TestLive**: Basic LiveView with counter state and Vue component integration
- **LiveVue.E2E.NavigationLive**: LiveView for testing navigation hooks with URL params and query params
- **LiveVue.E2E.Endpoint**: Phoenix endpoint with static asset serving and WebSocket support
- **LiveVue.E2E.Hooks**: Provides `sandbox:eval` functionality for executing Elixir code from tests
- **Health Check**: `/health` endpoint for Playwright server readiness checks

#### Test Utilities (`test/e2e/utils.js`)
- `syncLV(page)` - Wait for LiveView connection and loading states to complete
- `evalLV(page, code)` - Execute Elixir code within LiveView process from JavaScript

#### Vue Components (`test/e2e/vue/`)
- **counter.vue**: TypeScript Vue component with props and event emission
- **navigation.vue**: Vue component demonstrating `useLiveNavigation` hook usage
- Uses `$live.pushEvent()` to communicate with LiveView
- Demonstrates bidirectional data flow between Vue and LiveView

### Test Coverage
- ✅ Vue component rendering in LiveView
- ✅ Props passing from LiveView to Vue
- ✅ Event emission from Vue to LiveView
- ✅ LiveView/Vue state synchronization
- ✅ Server-side code execution from tests
- ✅ Navigation hook testing (patch and navigate functionality)

### E2E Test Development Best Practices

#### Component File Structure
- Vue components for E2E tests must be placed in `test/e2e/vue/` directory (not `test/e2e/js/vue/`)
- The build system uses `import.meta.glob("../vue/**/*.vue", { eager: true })` to discover components
- Component names in the `v-component` attribute must match the file name (without .vue extension)

#### LiveView Testing Patterns
- Use `handle_params/3` to capture both route params and query params from URL
- Use `assign(socket, key: value)` syntax, not `assign(socket, :key, value)`
- Always include both route params and query params in component props for comprehensive testing

#### Navigation Hook Testing
- `patch()` can take either a URL string or a query params object
- `navigate()` only accepts URL strings with query params included in the URL
- Test both patch (same route, different query params) and navigate (different route) scenarios
- Use relative URLs in tests (e.g., `/navigation/test1`) - the baseURL is configured in playwright.config.js

#### Debugging E2E Test Issues
- If `.phx-connected` element is hidden, check browser console for JavaScript errors
- Verify Vue components are in the correct directory (`test/e2e/vue/`)
- Ensure component names match between LiveView template and Vue file names
- Use Playwright traces and screenshots on failure for debugging

## Important Notes

- This is a library, not an application - use `example_project/` for testing
- `mix assets.watch` should be running in the background, you don't need to run it manually.
- Changes to library code are immediately available in `example_project/`
- Assets are TypeScript/JavaScript files that get packaged with the hex package
- E2E tests provide full integration testing of LiveView + Vue interactions
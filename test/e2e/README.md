# LiveVue End-to-End Tests

This directory contains end-to-end tests for the LiveVue library using Playwright.

## Setup

1. Install Playwright dependencies:
   ```bash
   npm run e2e:install
   npx playwright install
   ```

2. Install browsers:
   ```bash
   cd test/e2e && npx playwright install
   ```

## Running Tests

### Run all tests
```bash
npm run e2e:test
```

### Run tests with browser UI (headed mode)
```bash
npm run e2e:test:headed
```

### Debug tests interactively
```bash
npm run e2e:test:debug
```

### Run tests for a specific browser
```bash
cd test/e2e && npx playwright test --project=chromium
```

## Test Structure

- `playwright.config.js` - Playwright configuration
- `test_helper.exs` - Test server setup with Phoenix endpoint
- `utils.js` - JavaScript test utilities for LiveView/Vue synchronization
- `support/` - Test LiveViews and Vue components
- `tests/` - Actual test files

## Test Server

The test server runs on http://localhost:4004 and provides:

- `/health` - Health check endpoint
- `/test-vue` - Basic Vue component test
- `/test-vue-props` - Props passing test
- `/test-vue-events` - Event emission test

## Key Testing Utilities

- `syncLV(page)` - Wait for LiveView to be ready
- `syncVue(page)` - Wait for Vue components to be mounted
- `evalLV(page, code)` - Execute Elixir code in LiveView process

## Adding New Tests

1. Create test LiveViews in `support/test_live.ex`
2. Add corresponding Vue components in `support/vue_components.js`
3. Add routes in `test_helper.exs`
4. Write tests in `tests/` directory

## Current Test Coverage

- ✅ Vue component rendering in LiveView
- ✅ Props passing from LiveView to Vue
- ✅ Event emission from Vue to LiveView
- ✅ LiveView/Vue state synchronization
- ✅ Server-side code execution from tests

## Future Enhancements

- Form integration testing
- Component lifecycle testing
- Error handling scenarios
- Performance testing
- WebSocket reconnection testing
# LiveVue End-to-End Tests

This directory contains end-to-end tests for the LiveVue library using Playwright.

## Setup

1. Install Playwright browsers:
   ```bash
   npm run e2e:install
   ```

## Running Tests

```bash
npm run e2e:test           # Run all tests
npm run e2e:test:headed    # Run with browser UI
npm run e2e:test:debug     # Debug interactively
```

## Structure

Tests are organized as colocated features - each feature has its LiveView, Vue components, and tests in one directory:

```
test/e2e/
├── features/
│   ├── basic/              # Basic counter test
│   │   ├── live.ex         # LiveView module (LiveVue.E2E.TestLive)
│   │   ├── counter.vue     # Vue component
│   │   └── basic.spec.js   # Playwright test
│   ├── form/               # Form validation tests
│   ├── stream/             # LiveView streams tests
│   ├── event/              # useLiveEvent tests
│   ├── event-reply/        # Event reply tests
│   ├── navigation/         # useLiveNavigation tests
│   ├── prop-diff/          # Prop diffing tests
│   ├── slot/               # Slot rendering tests
│   └── upload/             # File upload tests
├── js/
│   └── app.js              # Vue/LiveSocket bootstrap
├── test_helper.exs         # Phoenix endpoint, routes, layout
├── utils.js                # Test utilities
├── playwright.config.js
└── vite.config.js
```

## Adding a New Test Feature

1. Create directory: `test/e2e/features/my-feature/`

2. Add LiveView (`live.ex`):
   ```elixir
   defmodule LiveVue.E2E.MyFeatureLive do
     use Phoenix.LiveView

     def mount(_params, _session, socket) do
       {:ok, assign(socket, :data, "hello")}
     end

     def render(assigns) do
       ~H"""
       <LiveVue.vue data={@data} v-component="my_component" v-socket={@socket} />
       """
     end
   end
   ```

3. Add Vue component (`my_component.vue`):
   ```vue
   <script setup lang="ts">
   defineProps<{ data: string }>()
   </script>
   <template>
     <div data-testid="output">{{ data }}</div>
   </template>
   ```

4. Add route to `test_helper.exs`:
   ```elixir
   live "/my-feature", MyFeatureLive
   ```

5. Add test (`my-feature.spec.js`):
   ```javascript
   import { test, expect } from "@playwright/test"
   import { syncLV } from "../../utils.js"

   test("my feature works", async ({ page }) => {
     await page.goto("/my-feature")
     await syncLV(page)
     await expect(page.getByTestId("output")).toHaveText("hello")
   })
   ```

## Test Utilities

- `syncLV(page)` - Wait for LiveView to connect and finish loading
- `evalLV(page, code)` - Execute Elixir code in LiveView process (returns result)

## Test Server

Runs on http://localhost:4004. Routes are defined in `test_helper.exs`.

## Notes

- LiveView modules are compiled via `elixirc_paths(:e2e)` in `mix.exs`
- Vue components are discovered via `import.meta.glob("../features/**/*.vue")`
- Each feature can have multiple Vue components if needed

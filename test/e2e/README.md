# LiveVue End-to-End Tests

This directory contains the Phoenix server and the features for the end-to-end tests of the LiveVue
library. The tests themselves are ExUnit tests in `e2e_pw/`, run with
[playwright_ex](https://hex.pm/packages/playwright_ex) (needs Elixir 1.18+).

## Setup

1. Install Playwright browsers:
   ```bash
   MIX_ENV=e2e mix playwright.install chromium
   ```

## Running Tests

```bash
mix e2e.test                                 # Build the assets, run all tests
MIX_ENV=e2e mix test e2e_pw/form_test.exs    # Run one file (after npm run e2e:build)
```

To watch the browser, set `launch_options: [headless: false]` in the `:playwright, :test` config of
`config/config.exs`. To debug interactively, run with `PWDEBUG=1`.

## Structure

Tests are organized as colocated features - each feature has its LiveView, Vue components, and tests in one directory:

```
test/e2e/
├── features/
│   ├── basic/              # Basic counter test
│   │   ├── live.ex         # LiveView module (LiveVue.E2E.TestLive)
│   │   ├── counter.vue     # Vue component
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
├── server.exs              # Phoenix endpoint, routes, layout
├── test_helper.exs         # Runs the server standalone (npm run e2e:server)
└── vite.config.js
```

The tests are in `e2e_pw/`, one `*_test.exs` per feature.

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

4. Add route to `server.exs`:
   ```elixir
   live "/my-feature", MyFeatureLive
   ```

5. Add test (`e2e_pw/my_feature_test.exs`):
   ```elixir
   defmodule LiveVue.E2E.MyFeatureTest do
     use LiveVue.E2E.Case, async: true

     test "my feature works", %{page: page} do
       Page.goto!(page, "/my-feature")
       sync_lv(page)
       Expect.to_have_text!(Page.get_by_test_id(page, "output"), "hello")
     end
   end
   ```

## Test Utilities

- `sync_lv(page)` - Wait for LiveView to connect and finish loading
- `eval_lv(page, code)` - Execute Elixir code in LiveView process (returns result)

## Test Server

Runs on http://localhost:4004. Routes are defined in `server.exs`.

## Notes

- LiveView modules are compiled via `elixirc_paths(:e2e)` in `mix.exs`
- Vue components are discovered via `import.meta.glob("../features/**/*.vue")`
- Each feature can have multiple Vue components if needed

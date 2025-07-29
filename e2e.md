# End-to-End Testing for LiveVue

This document outlines how Phoenix LiveView implements comprehensive end-to-end testing and provides a roadmap for implementing similar e2e tests for LiveVue.

## Phoenix LiveView's E2E Testing Architecture

### Core Components

#### 1. Test Framework Stack
- **Playwright**: Main e2e testing framework supporting Chromium, Firefox, and Webkit
- **JavaScript/Node.js**: Test scripts written in JavaScript with ES modules
- **Elixir Test Server**: Custom Phoenix application serving LiveView pages for testing

#### 2. Test Server Setup (`test/e2e/test_helper.exs`)

Phoenix LiveView creates a dedicated test server with:

```elixir
# Custom endpoint configuration for e2e tests
Application.put_env(:phoenix_live_view, Phoenix.LiveViewTest.E2E.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4004],
  adapter: Bandit.PhoenixAdapter,
  server: true,
  # ... other config
)

# Custom layout that includes LiveView JavaScript client
defmodule Phoenix.LiveViewTest.E2E.Layout do
  use Phoenix.Component
  
  def render("live.html", assigns) do
    ~H"""
    <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
    <script src="/assets/phoenix/phoenix.min.js"></script>
    <script type="module">
      import {LiveSocket} from "/assets/phoenix_live_view/phoenix_live_view.esm.js"
      
      let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
      let liveSocket = new LiveSocket("/live", window.Phoenix.Socket, {
        params: {_csrf_token: csrfToken},
        hooks: {...Hooks, ...window.hooks}
      })
      liveSocket.connect()
      window.liveSocket = liveSocket
    </script>
    {@inner_content}
    """
  end
end
```

#### 3. Special Testing Hooks and Utilities

**Server-Side Eval Hook** (`test_helper.exs:86-99`):
```elixir
# Allows JavaScript tests to execute Elixir code inside LiveView processes
defp handle_eval_event("sandbox:eval", %{"value" => code}, socket) do
  {result, _} = Code.eval_string(code, [socket: socket], __ENV__)
  case result do
    {:noreply, %Phoenix.LiveView.Socket{} = socket} -> {:halt, %{}, socket}
    %Phoenix.LiveView.Socket{} = socket -> {:halt, %{}, socket}
    result -> {:halt, %{"result" => result}, socket}
  end
end
```

**JavaScript Test Utilities** (`test/e2e/utils.js`):

```javascript
// Synchronizes with LiveView state - waits for all pending operations
export const syncLV = async (page) => {
  const promises = [
    expect(page.locator(".phx-connected").first()).toBeVisible(),
    expect(page.locator(".phx-change-loading")).toHaveCount(0),
    expect(page.locator(".phx-click-loading")).toHaveCount(0),
    expect(page.locator(".phx-submit-loading")).toHaveCount(0),
  ];
  return Promise.all(promises);
};

// Executes Elixir code inside a LiveView process from JavaScript
export const evalLV = async (page, code, selector = "[data-phx-main]") =>
  await page.evaluate(([code, selector]) => {
    return new Promise((resolve) => {
      window.liveSocket.main.withinTargets(selector, (targetView, targetCtx) => {
        targetView.pushEvent("event", document.body, targetCtx, "sandbox:eval", 
          { value: code }, {}, ({ result }) => resolve(result));
      });
    });
  }, [code, selector]);

// Monitors DOM attribute changes during test execution
export const attributeMutations = (page, selector) => {
  const id = randomString(24);
  const promise = page.locator(selector).evaluate((target, id) => {
    return new Promise((resolve) => {
      const mutations = [];
      let observer;
      window[id] = () => {
        if (observer) observer.disconnect();
        resolve(mutations);
        delete window[id];
      };
      observer = new MutationObserver((mutationsList, _observer) => {
        mutationsList.forEach((mutation) => {
          if (mutation.type === "attributes") {
            mutations.push({
              attr: mutation.attributeName,
              oldValue: mutation.oldValue,
              newValue: mutation.target.getAttribute(mutation.attributeName),
            });
          }
        });
      }).observe(target, { attributes: true, attributeOldValue: true });
    });
  }, id);
  
  return () => {
    page.locator(selector).evaluate((_target, id) => window[id](), id);
    return promise;
  };
};
```

#### 4. Playwright Configuration (`test/e2e/playwright.config.js`)

```javascript
const config = {
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  use: {
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    baseURL: "http://localhost:4004/",
  },
  webServer: {
    command: "npm run e2e:server",
    url: "http://127.0.0.1:4004/health",
    reuseExistingServer: !process.env.CI,
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox", use: { ...devices["Desktop Firefox"] } },
    { name: "webkit", use: { ...devices["Desktop Safari"] } },
  ],
};
```

### Key Testing Patterns

#### 1. **LiveView Synchronization**
Every test action is followed by `await syncLV(page)` to ensure:
- LiveView is connected (`.phx-connected` visible)
- No pending form changes (`.phx-change-loading` count is 0)
- No pending clicks (`.phx-click-loading` count is 0)
- No pending submits (`.phx-submit-loading` count is 0)

#### 2. **Server-Client Communication Testing**
```javascript
test("form state is recovered when socket reconnects", async ({ page }) => {
  await page.goto("/form");
  await syncLV(page);
  
  // Fill form fields
  await page.locator("input[name=b]").fill("test");
  await page.locator("select[name=d]").selectOption("bar");
  await syncLV(page);
  
  // Disconnect WebSocket
  await page.evaluate(() => 
    new Promise((resolve) => window.liveSocket.disconnect(resolve))
  );
  await expect(page.locator(".phx-loading")).toHaveCount(1);
  
  // Reconnect and verify state recovery
  await page.evaluate(() => window.liveSocket.connect());
  await syncLV(page);
  
  await expect(page.locator("input[name=b]")).toHaveValue("test");
  await expect(page.locator("select[name=d]")).toHaveValue("bar");
});
```

#### 3. **DOM Mutation Testing**
```javascript
test("button disabled state is restored after submits", async ({ page }) => {
  await page.goto("/form");
  await syncLV(page);
  
  const changes = attributeMutations(page, "#submit");
  await page.locator("#submit").click();
  await syncLV(page);
  
  // Verify the sequence of attribute changes during submit
  expect(await changes()).toEqual(expect.arrayContaining([
    { attr: "data-phx-disabled", oldValue: null, newValue: "false" },
    { attr: "disabled", oldValue: null, newValue: "" },
    { attr: "class", oldValue: null, newValue: "phx-submit-loading" },
    { attr: "data-phx-disabled", oldValue: "false", newValue: null },
    { attr: "disabled", oldValue: "", newValue: null },
    { attr: "class", oldValue: "phx-submit-loading", newValue: null },
  ]));
});
```

#### 4. **Server-Side State Inspection**
```javascript
// Execute Elixir code inside the LiveView process
const { lv_pid } = await evalLV(page, `
  <<"#PID"::binary, pid::binary>> = inspect(self())
  pid_parts = pid |> String.trim_leading("<") |> String.trim_trailing(">") |> String.split(".")
  %{lv_pid: pid_parts}
`);
```

#### 5. **WebSocket Event Monitoring**
```javascript
let webSocketEvents = [];
page.on("websocket", (ws) => {
  ws.on("framesent", (event) => 
    webSocketEvents.push({ type: "sent", payload: event.payload }));
  ws.on("framereceived", (event) => 
    webSocketEvents.push({ type: "received", payload: event.payload }));
  ws.on("close", () => webSocketEvents.push({ type: "close" }));
});
```

## Implementation Plan for LiveVue

### Phase 1: Basic Infrastructure

#### 1. Create E2E Test Directory Structure
```
test/
  e2e/
    README.md
    playwright.config.js
    test_helper.exs
    utils.js
    support/
      test_live.ex
    tests/
      basic.spec.js
      vue_components.spec.js
```

#### 2. Set Up Test Server (`test/e2e/test_helper.exs`)
```elixir
# Configure test endpoint
Application.put_env(:live_vue, LiveVue.E2E.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4004],
  adapter: Bandit.PhoenixAdapter,
  server: true,
  live_view: [signing_salt: "test_salt"],
  secret_key_base: String.duplicate("a", 64),
  pubsub_server: LiveVue.E2E.PubSub
)

defmodule LiveVue.E2E.Layout do
  use Phoenix.Component
  
  def render("live.html", assigns) do
    ~H"""
    <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
    <script src="/assets/phoenix/phoenix.min.js"></script>
    <script src="/assets/vue/vue.global.js"></script>
    <script type="module">
      import {LiveSocket} from "/assets/phoenix_live_view/phoenix_live_view.esm.js"
      
      let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
      let liveSocket = new LiveSocket("/live", window.Phoenix.Socket, {
        params: {_csrf_token: csrfToken}
      })
      liveSocket.connect()
      window.liveSocket = liveSocket
    </script>
    {@inner_content}
    """
  end
end

# Add eval hook for server-side testing
defmodule LiveVue.E2E.Hooks do
  import Phoenix.LiveView
  
  def on_mount(:default, _params, _session, socket) do
    socket
    |> attach_hook(:eval_handler, :handle_event, &handle_eval_event/3)
    |> then(&{:cont, &1})
  end
  
  defp handle_eval_event("sandbox:eval", %{"value" => code}, socket) do
    {result, _} = Code.eval_string(code, [socket: socket], __ENV__)
    case result do
      {:noreply, %Phoenix.LiveView.Socket{} = socket} -> {:halt, %{}, socket}
      %Phoenix.LiveView.Socket{} = socket -> {:halt, %{}, socket}
      result -> {:halt, %{"result" => result}, socket}
    end
  end
  
  defp handle_eval_event(_, _, socket), do: {:cont, socket}
end
```

#### 3. Create Test Utilities (`test/e2e/utils.js`)
```javascript
import { expect } from "@playwright/test";

// Wait for LiveView to be ready and Vue components to be mounted
export const syncLV = async (page) => {
  const promises = [
    expect(page.locator(".phx-connected").first()).toBeVisible(),
    expect(page.locator(".phx-change-loading")).toHaveCount(0),
    expect(page.locator(".phx-click-loading")).toHaveCount(0),
    expect(page.locator(".phx-submit-loading")).toHaveCount(0),
  ];
  return Promise.all(promises);
};

// Wait for Vue components to be mounted
export const syncVue = async (page) => {
  await page.waitForFunction(() => {
    const vueComponents = document.querySelectorAll('[data-live-vue-component]');
    return Array.from(vueComponents).every(el => el.__vue_app__);
  });
};

// Execute code inside LiveView process
export const evalLV = async (page, code, selector = "[data-phx-main]") =>
  await page.evaluate(([code, selector]) => {
    return new Promise((resolve) => {
      window.liveSocket.main.withinTargets(selector, (targetView, targetCtx) => {
        targetView.pushEvent("event", document.body, targetCtx, "sandbox:eval", 
          { value: code }, {}, ({ result }) => resolve(result));
      });
    });
  }, [code, selector]);

// Get Vue component instance for testing
export const getVueComponent = async (page, selector) => {
  return await page.evaluate((selector) => {
    const el = document.querySelector(selector);
    return el?.__vue_app__?.config?.globalProperties || null;
  }, selector);
};
```

#### 4. Configure Playwright (`test/e2e/playwright.config.js`)
```javascript
const config = {
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  use: {
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    baseURL: "http://localhost:4004/",
  },
  webServer: {
    command: "MIX_ENV=e2e mix run test/e2e/test_helper.exs",
    url: "http://127.0.0.1:4004/health",
    reuseExistingServer: !process.env.CI,
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox", use: { ...devices["Desktop Firefox"] } },
    { name: "webkit", use: { ...devices["Desktop Safari"] } },
  ],
};
```

### Phase 2: LiveVue-Specific Testing

#### 1. Test LiveView with Vue Components (`test/e2e/tests/vue_components.spec.js`)
```javascript
import { test, expect } from "@playwright/test";
import { syncLV, syncVue, evalLV } from "../utils";

test("renders Vue component inside LiveView", async ({ page }) => {
  await page.goto("/test-vue");
  await syncLV(page);
  await syncVue(page);
  
  // Verify Vue component is mounted
  await expect(page.locator('[data-live-vue-component="MyComponent"]')).toBeVisible();
  
  // Test Vue component interactivity
  await page.locator('#vue-button').click();
  await expect(page.locator('#vue-counter')).toHaveText('1');
});

test("Vue component receives props from LiveView", async ({ page }) => {
  await page.goto("/test-vue-props");
  await syncLV(page);
  await syncVue(page);
  
  // Verify initial props
  await expect(page.locator('#vue-message')).toHaveText('Hello from LiveView');
  
  // Update props from server
  await evalLV(page, `
    {:noreply, assign(socket, :message, "Updated message")}
  `);
  
  await syncLV(page);
  await expect(page.locator('#vue-message')).toHaveText('Updated message');
});

test("Vue component emits events to LiveView", async ({ page }) => {
  await page.goto("/test-vue-events");
  await syncLV(page);
  await syncVue(page);
  
  // Trigger Vue event
  await page.locator('#vue-emit-button').click();
  
  // Verify LiveView received the event
  await syncLV(page);
  await expect(page.locator('#server-response')).toHaveText('Event received!');
});
```

#### 2. Test Form Integration (`test/e2e/tests/forms.spec.js`)
```javascript
test("Vue form component submits to LiveView", async ({ page }) => {
  await page.goto("/test-vue-form");
  await syncLV(page);
  await syncVue(page);
  
  // Fill Vue form
  await page.locator('#vue-form input[name="name"]').fill('John Doe');
  await page.locator('#vue-form input[name="email"]').fill('john@example.com');
  
  // Submit form
  await page.locator('#vue-form button[type="submit"]').click();
  
  await syncLV(page);
  
  // Verify form submission was handled by LiveView
  await expect(page.locator('#form-result')).toContainText('John Doe');
  await expect(page.locator('#form-result')).toContainText('john@example.com');
});
```

#### 3. Test State Synchronization
```javascript
test("maintains Vue component state during LiveView updates", async ({ page }) => {
  await page.goto("/test-vue-state");
  await syncLV(page);
  await syncVue(page);
  
  // Set Vue component state
  await page.locator('#vue-input').fill('local state');
  
  // Trigger LiveView update that doesn't affect Vue component
  await page.locator('#server-update-button').click();
  await syncLV(page);
  
  // Verify Vue state is preserved
  await expect(page.locator('#vue-input')).toHaveValue('local state');
});
```

### Phase 3: Advanced Testing Features

#### 1. Component Lifecycle Testing
- Test Vue component mounting/unmounting
- Test component prop updates
- Test component event emission

#### 2. Error Handling Testing
- Test Vue component errors
- Test LiveView reconnection with Vue components
- Test malformed props handling

#### 3. Performance Testing
- Test component rendering performance
- Test large dataset handling
- Test memory leaks

### Phase 4: CI/CD Integration

#### 1. Package.json Scripts
```json
{
  "scripts": {
    "e2e:server": "MIX_ENV=e2e mix run test/e2e/test_helper.exs",
    "e2e:test": "cd test/e2e && npx playwright test",
    "e2e:test:headed": "cd test/e2e && npx playwright test --headed",
    "e2e:test:debug": "cd test/e2e && npx playwright test --debug"
  }
}
```

#### 2. GitHub Actions Integration
```yaml
- name: Run E2E Tests
  run: |
    npm install
    npx playwright install
    npm run e2e:test
```

## Key Takeaways

1. **Dual Architecture**: Phoenix LiveView's e2e tests manage both Elixir server processes and JavaScript browser automation
2. **Synchronization is Critical**: Every test action must wait for both LiveView and client-side state to stabilize
3. **Server-Side Inspection**: The ability to execute Elixir code from JavaScript tests is powerful for debugging
4. **Comprehensive Coverage**: Tests cover WebSocket communication, DOM mutations, state recovery, and error scenarios
5. **Multi-Browser Support**: All tests run across Chromium, Firefox, and WebKit for comprehensive compatibility

This architecture provides a robust foundation for testing complex client-server interactions in LiveVue applications.
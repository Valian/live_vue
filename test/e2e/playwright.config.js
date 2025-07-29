import { defineConfig, devices } from "@playwright/test"

export default defineConfig({
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  use: {
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    baseURL: "http://localhost:4004/",
  },
  webServer: {
    command: "cd ../.. && MIX_ENV=e2e mix run test/e2e/test_helper.exs",
    url: "http://127.0.0.1:4004/health",
    reuseExistingServer: !process.env.CI,
    timeout: 60_000,
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    // { name: "firefox", use: { ...devices["Desktop Firefox"] } },
    // { name: "webkit", use: { ...devices["Desktop Safari"] } },
  ],
})

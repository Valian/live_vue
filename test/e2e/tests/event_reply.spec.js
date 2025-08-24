import { test, expect } from "@playwright/test"
import { syncLV, evalLV } from "../utils.js"

test.describe("useEventReply E2E Tests", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/event-reply-test")
    await syncLV(page)
  })

  test("component initializes correctly", async ({ page }) => {
    // Verify component is mounted
    await expect(page.locator("[data-pw-event-reply-test]")).toBeVisible()
    await expect(page.locator("[data-pw-server-counter]")).toHaveText("Server Counter: 0")

    // Initial state should be empty
    await expect(page.locator("[data-pw-increment-loading]")).toHaveText("Loading: false")
    await expect(page.locator("[data-pw-increment-data]")).toHaveText("Data: null")
  })

  test("increment event with reply works correctly", async ({ page }) => {
    // Click increment by 1
    await page.locator("[data-pw-increment-1]").click()
    await syncLV(page)

    // Check server state updated
    await expect(page.locator("[data-pw-server-counter]")).toHaveText("Server Counter: 1")

    // Check client state received reply
    await expect(page.locator("[data-pw-increment-loading]")).toHaveText("Loading: false")
    await expect(page.locator("[data-pw-increment-data]")).toContainText('"counter":1')

    // Click increment by 5
    await page.locator("[data-pw-increment-5]").click()
    await syncLV(page)

    // Check server counter is now 6
    await expect(page.locator("[data-pw-server-counter]")).toHaveText("Server Counter: 6")
    await expect(page.locator("[data-pw-increment-data]")).toContainText('"counter":6')
  })

  test("user data fetching with different IDs", async ({ page }) => {
    // Fetch user 1
    await page.locator("[data-pw-fetch-user-1]").click()
    await syncLV(page)

    await expect(page.locator("[data-pw-user-loading]")).toHaveText("Loading: false")
    await expect(page.locator("[data-pw-user-data]")).toContainText('"name":"John Doe"')
    await expect(page.locator("[data-pw-user-data]")).toContainText('"email":"john@example.com"')

    // Fetch user 2
    await page.locator("[data-pw-fetch-user-2]").click()
    await syncLV(page)

    await expect(page.locator("[data-pw-user-data]")).toContainText('"name":"Jane Smith"')
    await expect(page.locator("[data-pw-user-data]")).toContainText('"email":"jane@example.com"')

    // Fetch unknown user
    await page.locator("[data-pw-fetch-user-999]").click()
    await syncLV(page)

    await expect(page.locator("[data-pw-user-data]")).toContainText('"name":"Unknown User"')
  })

  test("server error response handling works correctly", async ({ page }) => {
    // Trigger server error response
    await page.locator("[data-pw-trigger-error]").click()
    await syncLV(page)

    // Should receive error in data (server returns error as valid response data)
    await expect(page.locator("[data-pw-error-loading]")).toHaveText("Loading: false")
    await expect(page.locator("[data-pw-error-data]")).toContainText('"error":"Something went wrong on the server"')
  })

  test("no parameters event works", async ({ page }) => {
    // Test ping without parameters
    await page.locator("[data-pw-ping]").click()
    await syncLV(page)

    await expect(page.locator("[data-pw-ping-loading]")).toHaveText("Loading: false")
    await expect(page.locator("[data-pw-ping-data]")).toContainText('"response":"pong"')
  })

  test("different data types are handled correctly", async ({ page }) => {
    // Test string - now wrapped in {data: "Hello World"}
    await page.locator("[data-pw-test-string]").click()
    await syncLV(page)
    await expect(page.locator("[data-pw-datatype-data]")).toContainText('"data":"Hello World"')

    // Test number - now wrapped in {data: 42}
    await page.locator("[data-pw-test-number]").click()
    await syncLV(page)
    await expect(page.locator("[data-pw-datatype-data]")).toContainText('"data":42')

    // Test boolean - now wrapped in {data: true}
    await page.locator("[data-pw-test-boolean]").click()
    await syncLV(page)
    await expect(page.locator("[data-pw-datatype-data]")).toContainText('"data":true')

    // Test array - now wrapped in {data: [1,2,3,"four",true]}
    await page.locator("[data-pw-test-array]").click()
    await syncLV(page)
    await expect(page.locator("[data-pw-datatype-data]")).toContainText('"data":[1,2,3,"four",true]')

    // Test object - now wrapped in {data: {nested: {value: "test"}, count: 5}}
    await page.locator("[data-pw-test-object]").click()
    await syncLV(page)
    // Check for key components since JSON key order isn't guaranteed
    const objectData = page.locator("[data-pw-datatype-data]")
    await expect(objectData).toContainText('"data":')
    await expect(objectData).toContainText('"nested":{"value":"test"}')
    await expect(objectData).toContainText('"count":5')

    // Test null - now wrapped in {data: null}
    await page.locator("[data-pw-test-null]").click()
    await syncLV(page)
    await expect(page.locator("[data-pw-datatype-data]")).toContainText('"data":null')
  })

  test("input validation with server-side logic", async ({ page }) => {
    // Test short input (invalid)
    await page.locator("[data-pw-validate-short]").click()
    await syncLV(page)

    await expect(page.locator("[data-pw-validate-data]")).toContainText('"valid":false')
    await expect(page.locator("[data-pw-validate-data]")).toContainText('"error":"Input too short"')

    // Test valid input
    await page.locator("[data-pw-validate-valid]").click()
    await syncLV(page)

    await expect(page.locator("[data-pw-validate-data]")).toContainText('"valid":true')
    await expect(page.locator("[data-pw-validate-data]")).toContainText('"message":"Input is valid"')

    // Test long input (invalid)
    await page.locator("[data-pw-validate-long]").click()
    await syncLV(page)

    await expect(page.locator("[data-pw-validate-data]")).toContainText('"valid":false')
    await expect(page.locator("[data-pw-validate-data]")).toContainText('"error":"Input too long"')
  })

  test("cancellation functionality works", async ({ page }) => {
    // Start slow event
    await page.locator("[data-pw-start-slow]").click()

    // Should be loading immediately
    await expect(page.locator("[data-pw-slow-loading]")).toHaveText("Loading: true")

    // Cancel before it completes
    await page.locator("[data-pw-cancel-slow]").click()

    // Should not be loading after cancel
    await expect(page.locator("[data-pw-slow-loading]")).toHaveText("Loading: false")

    // Data should remain null (cancelled)
    await expect(page.locator("[data-pw-slow-data]")).toHaveText("Data: null")

    // Wait a bit to ensure the server response would have arrived
    await page.waitForTimeout(500)
    await syncLV(page)

    // Data should still be null (response ignored)
    await expect(page.locator("[data-pw-slow-data]")).toHaveText("Data: null")
  })

  test("concurrent execution prevention works", async ({ page }) => {
    // Start first slow event
    await page.locator("[data-pw-concurrent-first]").click()

    // Should be loading
    await expect(page.locator("[data-pw-slow-loading]")).toHaveText("Loading: true")

    // Try to start second event - should be rejected
    await page.locator("[data-pw-concurrent-second]").click()

    // Should still show loading from first event only
    await expect(page.locator("[data-pw-slow-loading]")).toHaveText("Loading: true")

    // Wait for first event to complete
    await page.waitForTimeout(1200)
    await syncLV(page)

    // Should now show completed first event
    await expect(page.locator("[data-pw-slow-loading]")).toHaveText("Loading: false")
    await expect(page.locator("[data-pw-slow-data]")).toContainText('"message":"Slow response after 1000ms"')
  })

  test("multiple different composables work independently", async ({ page }) => {
    // Execute multiple different events in quick succession
    await page.locator("[data-pw-increment-1]").click()
    await page.locator("[data-pw-fetch-user-1]").click()
    await page.locator("[data-pw-ping]").click()

    await page.waitForTimeout(100)

    // All should complete successfully and independently
    await expect(page.locator("[data-pw-increment-data]")).toContainText('"counter":1')
    await expect(page.locator("[data-pw-user-data]")).toContainText('"name":"John Doe"')
    await expect(page.locator("[data-pw-ping-data]")).toContainText('"response":"pong"')

    // All should be not loading
    await expect(page.locator("[data-pw-increment-loading]")).toHaveText("Loading: false")
    await expect(page.locator("[data-pw-user-loading]")).toHaveText("Loading: false")
    await expect(page.locator("[data-pw-ping-loading]")).toHaveText("Loading: false")
  })

  test("component state persists across LiveView updates", async ({ page }) => {
    // Execute an event to get some data
    await page.locator("[data-pw-increment-5]").click()
    await syncLV(page)

    await expect(page.locator("[data-pw-increment-data]")).toContainText('"counter":5')

    // Trigger another server update that doesn't affect this composable
    await page.locator("[data-pw-fetch-user-1]").click()
    await syncLV(page)

    // Original increment data should still be there
    await expect(page.locator("[data-pw-increment-data]")).toContainText('"counter":5')
    await expect(page.locator("[data-pw-user-data]")).toContainText('"name":"John Doe"')
  })

  test("loading states are accurate", async ({ page }) => {
    // All should start as not loading
    await expect(page.locator("[data-pw-slow-loading]")).toHaveText("Loading: false")

    // Start slow event and verify loading state immediately
    await page.locator("[data-pw-start-slow]").click()

    // Should be loading now
    await expect(page.locator("[data-pw-slow-loading]")).toHaveText("Loading: true")

    // Wait for completion
    await page.waitForTimeout(2200)
    await syncLV(page)

    // Should be done loading
    await expect(page.locator("[data-pw-slow-loading]")).toHaveText("Loading: false")
    await expect(page.locator("[data-pw-slow-data]")).toContainText("Slow response after 2000ms")
  })
})

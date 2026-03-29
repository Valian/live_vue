import { test, expect } from "@playwright/test"
import { syncLV } from "../../utils.js"

test.describe("LiveVue Reconnect", () => {
  test("props are refreshed from server after socket reconnect", async ({ page }) => {
    await page.goto("/reconnect")
    await syncLV(page)

    // Verify initial state
    await expect(page.locator("[data-pw-count]")).toHaveText("0")
    await expect(page.locator("[data-pw-label]")).toHaveText("initial")

    // Update state — this sends a diff via data-props-diff
    await page.locator("button").click()
    await syncLV(page)
    await expect(page.locator("[data-pw-count]")).toHaveText("1")
    await expect(page.locator("[data-pw-label]")).toHaveText("updated")

    // Disconnect and reconnect.
    // The LV process dies, so on reconnect a new process is spawned
    // with fresh mount state (count=0, label="initial").
    // Without the fix, the stale data-props-diff from the last update
    // would be re-applied, leaving Vue showing the old state.
    await page.evaluate(() => {
      return new Promise(resolve => {
        window.liveSocket.disconnect(() => {
          setTimeout(() => {
            window.liveSocket.connect()
            resolve()
          }, 200)
        })
      })
    })
    await syncLV(page)

    // New process mounted with initial state — Vue must reflect that
    await expect(page.locator("[data-pw-count]")).toHaveText("0")
    await expect(page.locator("[data-pw-label]")).toHaveText("initial")
  })
})

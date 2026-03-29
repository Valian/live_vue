import { test, expect } from "@playwright/test"
import { syncLV } from "../../utils.js"

const reconnect = async page => {
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
}

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
    // Without the fix, the stale data-props-diff from the last update
    // would be re-applied, leaving Vue showing the old state.
    await reconnect(page)

    // New process mounted with initial state — Vue must reflect that
    await expect(page.locator("[data-pw-count]")).toHaveText("0")
    await expect(page.locator("[data-pw-label]")).toHaveText("initial")
  })

  test("streams are restored after socket reconnect", async ({ page }) => {
    await page.goto("/reconnect")
    await syncLV(page)

    // Verify initial stream: 3 items
    await expect(page.locator("[data-pw-item-count]")).toHaveText("3")
    await expect(page.locator("[data-pw-item='1']")).toHaveText("Alpha")
    await expect(page.locator("[data-pw-item='2']")).toHaveText("Beta")
    await expect(page.locator("[data-pw-item='3']")).toHaveText("Gamma")

    // Update — adds a 4th stream item
    await page.locator("button").click()
    await syncLV(page)
    await expect(page.locator("[data-pw-item-count]")).toHaveText("4")
    await expect(page.locator("[data-pw-item='4']")).toHaveText("Delta")

    // Reconnect — new process re-mounts with only the original 3 items
    await reconnect(page)

    await expect(page.locator("[data-pw-item-count]")).toHaveText("3")
    await expect(page.locator("[data-pw-item='1']")).toHaveText("Alpha")
    await expect(page.locator("[data-pw-item='2']")).toHaveText("Beta")
    await expect(page.locator("[data-pw-item='3']")).toHaveText("Gamma")
    await expect(page.locator("[data-pw-item='4']")).toHaveCount(0)
  })
})

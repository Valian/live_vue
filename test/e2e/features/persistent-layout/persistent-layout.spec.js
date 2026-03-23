import { test, expect } from "@playwright/test"
import { evalLV } from "../../utils.js"

const waitForPage = async (page, text) =>
  expect(page.locator("[data-pw-page]")).toHaveText(text, { timeout: 5000 })

test("layout state persists across push_patch navigation", async ({ page }) => {
  await page.goto("/persistent-layout/page1")
  await waitForPage(page, "page1")

  // Increment layout counter a few times
  await page.locator("[data-pw-layout-btn]").click()
  await page.locator("[data-pw-layout-btn]").click()
  await page.locator("[data-pw-layout-btn]").click()
  await expect(page.locator("[data-pw-layout-counter]")).toHaveText("3")

  // Navigate to page2 via push_patch
  await evalLV(page, `{:noreply, Phoenix.LiveView.push_patch(socket, to: "/persistent-layout/page2")}`)
  await waitForPage(page, "page2")

  // Layout counter should be preserved (Vue state survived navigation)
  await expect(page.locator("[data-pw-layout-counter]")).toHaveText("3")

  // Page component should see layout counter via slot props
  await expect(page.locator("[data-pw-page-layout-count]")).toHaveText("3")

  // Incrementing layout counter should update in both places
  await page.locator("[data-pw-layout-btn]").click()
  await expect(page.locator("[data-pw-layout-counter]")).toHaveText("4")
  await expect(page.locator("[data-pw-page-layout-count]")).toHaveText("4")
})

test("nested injection: component injected into an injected component", async ({ page }) => {
  await page.goto("/persistent-layout/page1")
  await waitForPage(page, "page1")

  // Nested component should render inside the page component's slot
  await expect(page.locator("[data-pw-nested]")).toHaveText("I'm nested!")

  // Navigate — nested should survive (it's inside the persistent layout tree)
  await evalLV(page, `{:noreply, Phoenix.LiveView.push_patch(socket, to: "/persistent-layout/page2")}`)
  await waitForPage(page, "page2")

  // Nested component should still be there
  await expect(page.locator("[data-pw-nested]")).toHaveText("I'm nested!")
})

test("named slot injection via v-inject:slotname", async ({ page }) => {
  await page.goto("/persistent-layout/page1")
  await waitForPage(page, "page1")

  // Sidebar should render in the named slot with slot props
  await expect(page.locator("[data-pw-sidebar-content]")).toContainText("Sidebar")
  await expect(page.locator("[data-pw-sidebar-content]")).toContainText("layout: 0")

  // Incrementing layout counter should update sidebar's slot props too
  await page.locator("[data-pw-layout-btn]").click()
  await expect(page.locator("[data-pw-sidebar-content]")).toContainText("layout: 1")
})

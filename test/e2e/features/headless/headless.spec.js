import { test, expect } from "@playwright/test"
import { syncLV } from "../../utils.js"

test("headless component exposes reactive props via useLiveVue(elementId)", async ({ page }) => {
  await page.goto("/headless")
  await syncLV(page)

  await expect(page.locator("[data-pw-count]")).toHaveText("0")
  await expect(page.locator("[data-pw-label]")).toHaveText("Hello")

  await page.locator("[data-pw-increment]").click()
  await syncLV(page)
  await expect(page.locator("[data-pw-count]")).toHaveText("1")

  await page.locator("[data-pw-increment]").click()
  await syncLV(page)
  await expect(page.locator("[data-pw-count]")).toHaveText("2")
})

test("headless component updates non-numeric props reactively", async ({ page }) => {
  await page.goto("/headless")
  await syncLV(page)

  await expect(page.locator("[data-pw-label]")).toHaveText("Hello")

  await page.locator("[data-pw-label-input]").fill("Updated")
  await page.locator("[data-pw-update-label]").click()
  await syncLV(page)
  await expect(page.locator("[data-pw-label]")).toHaveText("Updated")
})

test("headless component renders no visible UI", async ({ page }) => {
  await page.goto("/headless")
  await syncLV(page)

  const headlessEl = page.locator("#data-source")
  await expect(headlessEl).toBeAttached()
  await expect(headlessEl).not.toHaveAttribute("data-name")
  await expect(headlessEl).toHaveText("")
})

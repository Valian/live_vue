import { expect, test } from '@playwright/test'
import { syncLV } from '../utils.js'

test.describe('LiveVue Basic E2E Tests', () => {
  test('renders Vue component inside LiveView and handles increment events', async ({ page }) => {
    await page.goto('/test')
    await syncLV(page)

    // Verify Vue component is mounted and displays initial count
    await expect(page.locator('[phx-hook="VueHook"]')).toBeVisible()
    await expect(page.locator('[data-pw-counter]')).toHaveText('0')

    // Verify the diff slider is present and has default value
    const diffSlider = page.locator('input[type="range"]')
    await expect(diffSlider).toBeVisible()
    await expect(diffSlider).toHaveValue('1')

    // Test incrementing by default value (1)
    await page.locator('button').click()
    await syncLV(page)
    await expect(page.locator('[phx-hook="VueHook"] [data-pw-counter]')).toHaveText('1')

    // Test incrementing by a different value (3)
    await diffSlider.fill('3')
    await page.locator('button').click()
    await syncLV(page)
    await expect(page.locator('[phx-hook="VueHook"] [data-pw-counter]')).toHaveText('4')

    // Test incrementing by maximum value (10)
    await diffSlider.fill('10')
    await page.locator('button').click()
    await syncLV(page)
    await expect(page.locator('[phx-hook="VueHook"] [data-pw-counter]')).toHaveText('14')
  })
})

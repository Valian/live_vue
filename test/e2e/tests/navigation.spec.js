import { expect, test } from '@playwright/test'
import { syncLV } from '../utils.js'

test.describe('useLiveNavigation', () => {
  test('should patch query params and navigate between routes', async ({ page }) => {
    // Start at the first navigation route
    await page.goto('/navigation/test1')
    await syncLV(page)

    // Verify initial state
    await expect(page.locator('#current-params')).toContainText('"page":"test1"')
    await expect(page.locator('#current-query')).toContainText('{}')

    // Test patch functionality - should update query params
    await page.click('#patch-btn')
    await syncLV(page)

    // Verify query params were updated
    await expect(page.locator('#current-query')).toContainText('"foo":"bar"')
    await expect(page.locator('#current-query')).toContainText('"timestamp"')
    // URL should still have the same page param but with query params
    await expect(page).toHaveURL(/\/navigation\/test1\?.*foo=bar/)

    // Test navigate functionality - should change to alt route
    await page.click('#navigate-btn')
    await syncLV(page)

    // Verify navigation to alt route
    await expect(page.locator('#current-params')).toContainText('"page":"test2"')
    await expect(page.locator('#current-query')).toContainText('"baz":"qux"')
    await expect(page).toHaveURL(/\/navigation\/alt\/test2\?.*baz=qux/)

    // Test navigate back
    await page.click('#navigate-back-btn')
    await syncLV(page)

    // Verify navigation back to original route
    await expect(page.locator('#current-params')).toContainText('"page":"test1"')
    await expect(page.locator('#current-query')).toContainText('{}')
    await expect(page).toHaveURL('/navigation/test1')
  })

  test('should handle direct route access with params', async ({ page }) => {
    // Test direct access to alt route with query params
    await page.goto('/navigation/alt/direct?test=value&count=42')
    await syncLV(page)

    // Verify params and query params are correctly parsed
    await expect(page.locator('#current-params')).toContainText('"page":"direct"')
    await expect(page.locator('#current-query')).toContainText('"test":"value"')
    await expect(page.locator('#current-query')).toContainText('"count":"42"')
  })
})

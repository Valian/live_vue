import { test, expect } from "@playwright/test"
import { syncLV } from "../utils.js"

test.describe("LiveVue Stream Integration", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/streams")
    await syncLV(page)
  })

  test("renders initial stream items", async ({ page }) => {
    // Check that initial items are rendered
    await expect(page.locator('[data-testid="item-1"]')).toBeVisible()
    await expect(page.locator('[data-testid="item-2"]')).toBeVisible()
    await expect(page.locator('[data-testid="item-3"]')).toBeVisible()

    // Check item content
    await expect(page.locator('[data-testid="item-1"] [data-testid="item-name"]')).toHaveText("Item 1")
    await expect(page.locator('[data-testid="item-1"] [data-testid="item-description"]')).toHaveText("First item")
    await expect(page.locator('[data-testid="item-1"] [data-testid="item-id"]')).toHaveText("ID: 1")

    // Check item count
    const itemsHeading = page.locator('h3:has-text("Items")')
    await expect(itemsHeading).toHaveText("Items (3)")
  })

  test("adds new items to stream", async ({ page }) => {
    // Fill form and add new item
    await page.fill('[data-testid="name-input"]', "New Item")
    await page.fill('[data-testid="description-input"]', "This is a new item")
    await page.click('[data-testid="add-button"]')

    await syncLV(page)

    // Check that new item appears
    await expect(page.locator('[data-testid="item-4"]')).toBeVisible()
    await expect(page.locator('[data-testid="item-4"] [data-testid="item-name"]')).toHaveText("New Item")
    await expect(page.locator('[data-testid="item-4"] [data-testid="item-description"]')).toHaveText(
      "This is a new item"
    )
    await expect(page.locator('[data-testid="item-4"] [data-testid="item-id"]')).toHaveText("ID: 4")

    // Check updated count
    const itemsHeading = page.locator('h3:has-text("Items")')
    await expect(itemsHeading).toHaveText("Items (4)")

    // Check that form was cleared
    await expect(page.locator('[data-testid="name-input"]')).toHaveValue("")
    await expect(page.locator('[data-testid="description-input"]')).toHaveValue("")
  })

  test("adds multiple items in sequence", async ({ page }) => {
    // Add first item
    await page.fill('[data-testid="name-input"]', "Item A")
    await page.fill('[data-testid="description-input"]', "Description A")
    await page.click('[data-testid="add-button"]')
    await syncLV(page)

    // Add second item
    await page.fill('[data-testid="name-input"]', "Item B")
    await page.fill('[data-testid="description-input"]', "Description B")
    await page.click('[data-testid="add-button"]')
    await syncLV(page)

    // Check both items exist
    await expect(page.locator('[data-testid="item-4"]')).toBeVisible()
    await expect(page.locator('[data-testid="item-5"]')).toBeVisible()

    // Check count
    const itemsHeading = page.locator('h3:has-text("Items")')
    await expect(itemsHeading).toHaveText("Items (5)")
  })

  test("removes individual items from stream", async ({ page }) => {
    // Remove item 2
    await page.click('[data-testid="remove-2"]')
    await syncLV(page)

    // Check that item 2 is gone but others remain
    await expect(page.locator('[data-testid="item-1"]')).toBeVisible()
    await expect(page.locator('[data-testid="item-2"]')).not.toBeVisible()
    await expect(page.locator('[data-testid="item-3"]')).toBeVisible()

    // Check updated count
    const itemsHeading = page.locator('h3:has-text("Items")')
    await expect(itemsHeading).toHaveText("Items (2)")
  })

  test("removes multiple items", async ({ page }) => {
    // Remove items 1 and 3
    await page.click('[data-testid="remove-1"]')
    await syncLV(page)
    await page.click('[data-testid="remove-3"]')
    await syncLV(page)

    // Check only item 2 remains
    await expect(page.locator('[data-testid="item-1"]')).not.toBeVisible()
    await expect(page.locator('[data-testid="item-2"]')).toBeVisible()
    await expect(page.locator('[data-testid="item-3"]')).not.toBeVisible()

    // Check count
    const itemsHeading = page.locator('h3:has-text("Items")')
    await expect(itemsHeading).toHaveText("Items (1)")
  })

  test("clears entire stream", async ({ page }) => {
    // Clear all items
    await page.click('[data-testid="clear-button"]')
    await syncLV(page)

    // Check that all items are gone
    await expect(page.locator('[data-testid="item-1"]')).not.toBeVisible()
    await expect(page.locator('[data-testid="item-2"]')).not.toBeVisible()
    await expect(page.locator('[data-testid="item-3"]')).not.toBeVisible()

    // Check empty state
    await expect(page.locator('[data-testid="empty-message"]')).toBeVisible()
    await expect(page.locator('[data-testid="empty-message"]')).toHaveText("No items in the stream")

    // Check count
    const itemsHeading = page.locator('h3:has-text("Items")')
    await expect(itemsHeading).toHaveText("Items (0)")
  })

  test("resets stream to default state", async ({ page }) => {
    // First clear the stream
    await page.click('[data-testid="clear-button"]')
    await syncLV(page)
    await expect(page.locator('[data-testid="empty-message"]')).toBeVisible()

    // Then reset it
    await page.click('[data-testid="reset-button"]')
    await syncLV(page)

    // Check that original items are back
    await expect(page.locator('[data-testid="item-1"]')).toBeVisible()
    await expect(page.locator('[data-testid="item-2"]')).toBeVisible()
    await expect(page.locator('[data-testid="item-3"]')).toBeVisible()
    await expect(page.locator('[data-testid="empty-message"]')).not.toBeVisible()

    // Check count
    const itemsHeading = page.locator('h3:has-text("Items")')
    await expect(itemsHeading).toHaveText("Items (3)")
  })

  test("handles complex workflow: add, remove, clear, reset", async ({ page }) => {
    // Add a new item
    await page.fill('[data-testid="name-input"]', "Workflow Item")
    await page.fill('[data-testid="description-input"]', "Testing workflow")
    await page.click('[data-testid="add-button"]')
    await syncLV(page)

    // Verify we have 4 items
    const itemsHeading = page.locator('h3:has-text("Items")')
    await expect(itemsHeading).toHaveText("Items (4)")

    // Remove one original item
    await page.click('[data-testid="remove-2"]')
    await syncLV(page)
    await expect(itemsHeading).toHaveText("Items (3)")

    // Clear all
    await page.click('[data-testid="clear-button"]')
    await syncLV(page)
    await expect(itemsHeading).toHaveText("Items (0)")
    await expect(page.locator('[data-testid="empty-message"]')).toBeVisible()

    // Reset to defaults
    await page.click('[data-testid="reset-button"]')
    await syncLV(page)
    await expect(itemsHeading).toHaveText("Items (3)")
    await expect(page.locator('[data-testid="empty-message"]')).not.toBeVisible()

    // Verify the original 3 items are back (not the added one)
    await expect(page.locator('[data-testid="item-1"]')).toBeVisible()
    await expect(page.locator('[data-testid="item-2"]')).toBeVisible()
    await expect(page.locator('[data-testid="item-3"]')).toBeVisible()
    await expect(page.locator('[data-testid="item-4"]')).not.toBeVisible()
  })

  test("validates form input for adding items", async ({ page }) => {
    // Try to add item with empty name
    await page.fill('[data-testid="name-input"]', "")
    await page.fill('[data-testid="description-input"]', "Description only")

    // This should trigger an alert (form validation)
    page.on("dialog", async dialog => {
      expect(dialog.message()).toBe("Please enter a name for the item")
      await dialog.accept()
    })

    await page.click('[data-testid="add-button"]')

    // Item should not be added
    await syncLV(page)
    const itemsHeading = page.locator('h3:has-text("Items")')
    await expect(itemsHeading).toHaveText("Items (3)") // Still 3 items
  })

  test("displays debug information correctly", async ({ page }) => {
    // Check debug info shows correct type and length
    await expect(page.locator('.debug-info p:has-text("Items type:")')).toBeVisible()
    await expect(page.locator('.debug-info p:has-text("Items length:")')).toBeVisible()

    // Check raw items data is displayed
    await expect(page.locator('[data-testid="raw-items"]')).toBeVisible()

    const rawItemsText = await page.locator('[data-testid="raw-items"]').textContent()
    expect(rawItemsText).toContain('"id"')
    expect(rawItemsText).toContain('"name"')
    expect(rawItemsText).toContain('"description"')
  })

  test("maintains item order during operations", async ({ page }) => {
    // Get initial order
    const item1Name = await page.locator('[data-testid="item-1"] [data-testid="item-name"]').textContent()
    const item2Name = await page.locator('[data-testid="item-2"] [data-testid="item-name"]').textContent()
    const item3Name = await page.locator('[data-testid="item-3"] [data-testid="item-name"]').textContent()

    expect(item1Name).toBe("Item 1")
    expect(item2Name).toBe("Item 2")
    expect(item3Name).toBe("Item 3")

    // Add new item (should appear after existing ones)
    await page.fill('[data-testid="name-input"]', "Item 4")
    await page.fill('[data-testid="description-input"]', "Fourth item")
    await page.click('[data-testid="add-button"]')
    await syncLV(page)

    // Check that new item appears at the end
    const item4Name = await page.locator('[data-testid="item-4"] [data-testid="item-name"]').textContent()
    expect(item4Name).toBe("Item 4")

    // Remove middle item and check order is maintained
    await page.click('[data-testid="remove-2"]')
    await syncLV(page)

    // Items 1, 3, 4 should still be in correct order
    await expect(page.locator('[data-testid="item-1"] [data-testid="item-name"]')).toHaveText("Item 1")
    await expect(page.locator('[data-testid="item-3"] [data-testid="item-name"]')).toHaveText("Item 3")
    await expect(page.locator('[data-testid="item-4"] [data-testid="item-name"]')).toHaveText("Item 4")
  })

  // Limit operation tests
  test.describe("Limit Operations", () => {
    test.beforeEach(async ({ page }) => {
      await page.goto("/streams")
      await syncLV(page)
    })

    test("adds multiple items at start with positive limit", async ({ page }) => {
      // Verify initial state: 3 items
      await expect(page.locator('h3:has-text("Items")')).toHaveText("Items (3)")

      // Add 3 items at start with limit 5 (should keep first 5 items)
      await page.click('[data-testid="add-multiple-start-button"]')
      await syncLV(page)

      // Should have 5 items total (3 new + 3 original, but limited to 5)
      await expect(page.locator('h3:has-text("Items")')).toHaveText("Items (5)")

      // Check that new items are at the start and in correct order
      // Expected order: Start Item C, Start Item B, Start Item A, Item 1, Item 2
      // (Note: items are added at position 0 in reverse order)
      await expect(page.locator('[data-testid="item-6"] [data-testid="item-name"]')).toHaveText("Start Item C")
      await expect(page.locator('[data-testid="item-5"] [data-testid="item-name"]')).toHaveText("Start Item B")
      await expect(page.locator('[data-testid="item-4"] [data-testid="item-name"]')).toHaveText("Start Item A")
      await expect(page.locator('[data-testid="item-1"] [data-testid="item-name"]')).toHaveText("Item 1")
      await expect(page.locator('[data-testid="item-2"] [data-testid="item-name"]')).toHaveText("Item 2")

      // Item 3 should be removed due to limit 5
      await expect(page.locator('[data-testid="item-3"]')).not.toBeVisible()
    })

    test("adds multiple items at end with negative limit", async ({ page }) => {
      // Verify initial state: 3 items
      await expect(page.locator('h3:has-text("Items")')).toHaveText("Items (3)")

      // Add 3 items at end with negative limit -5 (should keep last 5 items)
      await page.click('[data-testid="add-multiple-end-button"]')
      await syncLV(page)

      // Should have 5 items total (3 original + 3 new, but limited to last 5)
      await expect(page.locator('h3:has-text("Items")')).toHaveText("Items (5)")

      // Check that new items are at the end and original items remain
      // Expected order: Item 2, Item 3, End Item X, End Item Y, End Item Z
      // (Item 1 should be removed due to negative limit -5)
      await expect(page.locator('[data-testid="item-1"]')).not.toBeVisible()
      await expect(page.locator('[data-testid="item-2"] [data-testid="item-name"]')).toHaveText("Item 2")
      await expect(page.locator('[data-testid="item-3"] [data-testid="item-name"]')).toHaveText("Item 3")
      await expect(page.locator('[data-testid="item-4"] [data-testid="item-name"]')).toHaveText("End Item X")
      await expect(page.locator('[data-testid="item-5"] [data-testid="item-name"]')).toHaveText("End Item Y")
      await expect(page.locator('[data-testid="item-6"] [data-testid="item-name"]')).toHaveText("End Item Z")
    })

    test("adds single item with custom positive limit", async ({ page }) => {
      // Set positive limit to 2
      await page.fill('[data-testid="positive-limit-input"]', "2")

      // Add item with positive limit 2
      await page.click('[data-testid="add-positive-limit-button"]')
      await syncLV(page)

      // Should have only 2 items (limited to first 2)
      await expect(page.locator('h3:has-text("Items")')).toHaveText("Items (2)")

      // Check which items remain (should be original Item 1 and new limited item)
      await expect(page.locator('[data-testid="item-1"] [data-testid="item-name"]')).toHaveText("Item 1")
      await expect(page.locator('[data-testid="item-4"] [data-testid="item-name"]')).toHaveText("Limited Item +2")

      // Items 2 and 3 should be removed
      await expect(page.locator('[data-testid="item-2"]')).not.toBeVisible()
      await expect(page.locator('[data-testid="item-3"]')).not.toBeVisible()
    })

    test("adds single item with custom negative limit", async ({ page }) => {
      // Set negative limit to 2
      await page.fill('[data-testid="negative-limit-input"]', "2")

      // Add item with negative limit -2
      await page.click('[data-testid="add-negative-limit-button"]')
      await syncLV(page)

      // Should have only 2 items (limited to last 2)
      await expect(page.locator('h3:has-text("Items")')).toHaveText("Items (2)")

      // Check which items remain (should be Item 3 and new limited item)
      await expect(page.locator('[data-testid="item-3"] [data-testid="item-name"]')).toHaveText("Item 3")
      await expect(page.locator('[data-testid="item-4"] [data-testid="item-name"]')).toHaveText("Limited Item -2")

      // Items 1 and 2 should be removed
      await expect(page.locator('[data-testid="item-1"]')).not.toBeVisible()
      await expect(page.locator('[data-testid="item-2"]')).not.toBeVisible()
    })

    test("handles limit operations with existing items", async ({ page }) => {
      // First add a regular item to have 4 items total
      await page.fill('[data-testid="name-input"]', "Regular Item")
      await page.fill('[data-testid="description-input"]', "Regular description")
      await page.click('[data-testid="add-button"]')
      await syncLV(page)

      // Should have 4 items
      await expect(page.locator('h3:has-text("Items")')).toHaveText("Items (4)")

      // Now prepend with positive limit 3
      await page.fill('[data-testid="positive-limit-input"]', "3")
      await page.click('[data-testid="add-positive-limit-button"]')
      await syncLV(page)

      // Should have 3 items (first 3 kept)
      await expect(page.locator('h3:has-text("Items")')).toHaveText("Items (3)")

      // Check that we have the first item, new regular item, and new limited item
      await expect(page.locator('[data-testid="item-5"] [data-testid="item-name"]')).toHaveText("Limited Item +3")
      await expect(page.locator('[data-testid="item-1"] [data-testid="item-name"]')).toHaveText("Item 1")
      await expect(page.locator('[data-testid="item-2"] [data-testid="item-name"]')).toHaveText("Item 2")
    })

    test("validates limit input constraints", async ({ page }) => {
      // Test that buttons are disabled for invalid inputs
      await expect(page.locator('[data-testid="add-positive-limit-button"]')).not.toBeDisabled()
      await expect(page.locator('[data-testid="add-negative-limit-button"]')).not.toBeDisabled()

      // Clear inputs should disable buttons
      await page.fill('[data-testid="positive-limit-input"]', "")
      await page.fill('[data-testid="negative-limit-input"]', "")

      await expect(page.locator('[data-testid="add-positive-limit-button"]')).toBeDisabled()
      await expect(page.locator('[data-testid="add-negative-limit-button"]')).toBeDisabled()

      // Zero should disable buttons
      await page.fill('[data-testid="positive-limit-input"]', "0")
      await page.fill('[data-testid="negative-limit-input"]', "0")

      await expect(page.locator('[data-testid="add-positive-limit-button"]')).toBeDisabled()
      await expect(page.locator('[data-testid="add-negative-limit-button"]')).toBeDisabled()

      // Valid values should enable buttons
      await page.fill('[data-testid="positive-limit-input"]', "3")
      await page.fill('[data-testid="negative-limit-input"]', "3")

      await expect(page.locator('[data-testid="add-positive-limit-button"]')).not.toBeDisabled()
      await expect(page.locator('[data-testid="add-negative-limit-button"]')).not.toBeDisabled()
    })

    test("handles limit operations in sequence", async ({ page }) => {
      // Start with positive limit
      await page.fill('[data-testid="positive-limit-input"]', "4")
      await page.click('[data-testid="add-positive-limit-button"]')
      await syncLV(page)

      // Should have 4 items
      await expect(page.locator('h3:has-text("Items")')).toHaveText("Items (4)")

      // Then apply negative limit
      await page.fill('[data-testid="negative-limit-input"]', "2")
      await page.click('[data-testid="add-negative-limit-button"]')
      await syncLV(page)

      // Should have 2 items (last 2)
      await expect(page.locator('h3:has-text("Items")')).toHaveText("Items (2)")

      // Verify it's the limited item and one original item
      await expect(page.locator('[data-testid="item-3"] [data-testid="item-name"]')).toHaveText("Item 3")
      await expect(page.locator('[data-testid="item-5"] [data-testid="item-name"]')).toHaveText("Limited Item -2")
    })
  })
})

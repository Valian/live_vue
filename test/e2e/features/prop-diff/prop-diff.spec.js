import { test, expect } from "@playwright/test"
import { syncLV } from "../../utils.js"

// Read and parse props from the page
const getProps = async page => {
  await syncLV(page)

  const propsJson = await page.locator('[data-testid="props-json"]').textContent()
  return JSON.parse(propsJson)
}

test.describe("LiveVue Prop Diff E2E Tests", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/prop-diff-test")
    await syncLV(page)

    // Verify Vue component is mounted
    await expect(page.locator('[phx-hook="VueHook"]')).toBeVisible()
  })

  test("initial render displays all props correctly", async ({ page }) => {
    // Check initial props are rendered
    const props = await getProps(page)

    expect(props.simple_string).toBe("hello")
    expect(props.simple_number).toBe(42)
    expect(props.simple_boolean).toBe(true)
    expect(props.simple_list).toEqual(["a", "b", "c"])
    expect(props.simple_map).toEqual({ key1: "value1", key2: "value2" })
    expect(props.nested_data.user).toEqual({ name: "John", age: 30 })
    expect(props.nested_data.settings).toEqual({ theme: "dark", notifications: true })
    expect(props.list_of_maps).toEqual([
      { id: 1, name: "Alice", role: "admin" },
      { id: 2, name: "Bob", role: "user" },
    ])
  })

  test("simple string change is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-change-string"]').click()

    const props = await getProps(page)

    expect(props.simple_string).toBe("changed")
    // Other props should remain unchanged
    expect(props.simple_number).toBe(42)
    expect(props.simple_boolean).toBe(true)
  })

  test("simple number change is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-change-number"]').click()

    const props = await getProps(page)

    expect(props.simple_number).toBe(99)
    // Other props should remain unchanged
    expect(props.simple_string).toBe("hello")
    expect(props.simple_boolean).toBe(true)
  })

  test("boolean toggle is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-toggle-boolean"]').click()

    const props = await getProps(page)

    expect(props.simple_boolean).toBe(false)

    // Toggle back
    await page.locator('[data-testid="btn-toggle-boolean"]').click()

    const props2 = await getProps(page)
    expect(props2.simple_boolean).toBe(true)
  })

  test("array addition is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-add-to-list"]').click()

    const props = await getProps(page)

    expect(props.simple_list).toEqual(["a", "b", "c", "d"])
  })

  test("array removal is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-remove-from-list"]').click()

    const props = await getProps(page)

    expect(props.simple_list).toEqual(["b", "c"])
  })

  test("array replacement is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-replace-in-list"]').click()

    const props = await getProps(page)

    expect(props.simple_list).toEqual(["a", "REPLACED", "c"])
  })

  test("map addition is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-add-to-map"]').click()

    const props = await getProps(page)

    expect(props.simple_map).toEqual({
      key1: "value1",
      key2: "value2",
      key3: "value3",
    })
  })

  test("map removal is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-remove-from-map"]').click()

    const props = await getProps(page)

    expect(props.simple_map).toEqual({ key2: "value2" })
  })

  test("nested object property change is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-change-nested-name"]').click()

    const props = await getProps(page)

    expect(props.nested_data.user.name).toBe("Jane")
    // Other nested properties should remain unchanged
    expect(props.nested_data.user.age).toBe(30)
    expect(props.nested_data.settings).toEqual({ theme: "dark", notifications: true })
  })

  test("nested object number change is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-change-nested-age"]').click()

    const props = await getProps(page)

    expect(props.nested_data.user.age).toBe(25)
    // Other properties should remain unchanged
    expect(props.nested_data.user.name).toBe("John")
  })

  test("adding nested property is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-add-nested-setting"]').click()

    const props = await getProps(page)

    expect(props.nested_data.settings).toEqual({
      theme: "dark",
      notifications: true,
      language: "en",
    })
  })

  test("setting value to nil is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-set-nil"]').click()

    const props = await getProps(page)

    expect(props.simple_string).toBe(null)
    // Other props should remain unchanged
    expect(props.simple_number).toBe(42)
    expect(props.simple_boolean).toBe(true)
  })

  test("adding item to list of maps is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-add-list-item"]').click()

    const props = await getProps(page)

    expect(props.list_of_maps).toEqual([
      { id: 1, name: "Alice", role: "admin" },
      { id: 2, name: "Bob", role: "user" },
      { id: 3, name: "Charlie", role: "guest" },
    ])
  })

  test("updating item in list of maps is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-update-list-item"]').click()

    const props = await getProps(page)

    expect(props.list_of_maps).toEqual([
      { id: 1, name: "Alice Updated", role: "admin" },
      { id: 2, name: "Bob", role: "user" },
    ])
  })

  test("removing item from list of maps is applied via diff", async ({ page }) => {
    await page.locator('[data-testid="btn-remove-list-item"]').click()

    const props = await getProps(page)

    expect(props.list_of_maps).toEqual([{ id: 1, name: "Alice", role: "admin" }])
  })

  test("multiple consecutive changes are applied correctly", async ({ page }) => {
    // Make multiple changes in sequence
    await page.locator('[data-testid="btn-change-string"]').click()
    await page.locator('[data-testid="btn-change-number"]').click()
    await page.locator('[data-testid="btn-add-to-list"]').click()
    await page.locator('[data-testid="btn-change-nested-name"]').click()

    const props = await getProps(page)

    expect(props.simple_string).toBe("changed")
    expect(props.simple_number).toBe(99)
    expect(props.simple_list).toEqual(["a", "b", "c", "d"])
    expect(props.nested_data.user.name).toBe("Jane")

    // Unchanged properties should remain the same
    expect(props.simple_boolean).toBe(true)
    expect(props.nested_data.user.age).toBe(30)
  })

  test("Vue component can access all updated props reactively", async ({ page }) => {
    // Verify that Vue component reactively updates when props change
    const initial = await getProps(page)

    // Make a change
    await page.locator('[data-testid="btn-change-string"]').click()

    // Wait for Vue to update (should be immediate)
    const updated = await getProps(page)

    // Verify the change is reflected immediately in the Vue component
    expect(updated.simple_string).toBe("changed")
    expect(updated.simple_string).not.toBe(initial.simple_string)
  })
})

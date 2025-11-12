import { expect, test } from '@playwright/test'
import { syncLV } from '../utils.js'

test.describe('useLiveForm E2E Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/form-test')
    await syncLV(page)
  })

  test('form initializes with empty state and is invalid', async ({ page }) => {
    // Verify form component is mounted
    await expect(page.locator('[data-pw-form]')).toBeVisible()

    // Check initial form state
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: false')
    await expect(page.locator('[data-pw-is-dirty]')).toHaveText('Dirty: false')
    await expect(page.locator('[data-pw-is-touched]')).toHaveText('Touched: false')

    // Submit button should be disabled initially
    await expect(page.locator('[data-pw-submit]')).toBeDisabled()
  })

  test('basic field validation and form state tracking', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')
    const acceptTermsCheckbox = page.locator('[data-pw-accept-terms]')

    // Fill name field (but not enough characters) - use type instead of fill
    await nameInput.type('A')
    await nameInput.blur()
    await page.waitForTimeout(500) // Give time for debounced events
    await syncLV(page)

    // Form should be touched and dirty but not valid
    await expect(page.locator('[data-pw-is-touched]')).toHaveText('Touched: true')
    await expect(page.locator('[data-pw-is-dirty]')).toHaveText('Dirty: true')
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: false')

    // Should show validation error after server validation
    await expect(page.locator('[data-pw-name-error]')).toBeVisible()

    // Fill valid data
    await nameInput.clear()
    await nameInput.type('John Doe')
    await emailInput.type('john@example.com')
    await acceptTermsCheckbox.check() // Accept terms is now required
    await page.waitForTimeout(500) // Give time for debounced events
    await syncLV(page)

    // Form should now be valid
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: true')
    await expect(page.locator('[data-pw-submit]')).toBeEnabled()
  })

  test('nested field validation (profile bio)', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')
    const bioInput = page.locator('[data-pw-bio-input]')
    const acceptTermsCheckbox = page.locator('[data-pw-accept-terms]')

    // Fill required fields first
    await nameInput.fill('John Doe')
    await emailInput.fill('john@example.com')
    await acceptTermsCheckbox.check()

    // Fill bio with insufficient content
    await bioInput.fill('Short')
    await bioInput.blur()
    await syncLV(page)

    // Should show bio validation error
    await expect(page.locator('[data-pw-bio-error]')).toBeVisible()
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: false')

    // Fill with valid bio
    await bioInput.fill('This is a valid bio with enough characters to pass validation')
    await bioInput.blur()
    await syncLV(page)

    // Form should be valid now
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: true')
  })

  test('array field operations - skills', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')

    // Fill required fields
    await nameInput.fill('John Doe')
    await emailInput.fill('john@example.com')

    // Initially no skills
    await expect(page.locator('[data-pw-skill-item]')).toHaveCount(0)

    // Add a skill
    await page.locator('[data-pw-add-skill]').click()
    await expect(page.locator('[data-pw-skill-item]')).toHaveCount(1)

    // Fill the skill
    await page.locator('[data-pw-skill-input="0"]').fill('JavaScript')
    await syncLV(page)

    // Add another skill
    await page.locator('[data-pw-add-skill]').click()
    await expect(page.locator('[data-pw-skill-item]')).toHaveCount(2)

    // Fill second skill
    await page.locator('[data-pw-skill-input="1"]').fill('TypeScript')
    await syncLV(page)

    // Remove first skill
    await page.locator('[data-pw-remove-skill="0"]').click()
    await expect(page.locator('[data-pw-skill-item]')).toHaveCount(1)

    // Remaining skill should be TypeScript
    await expect(page.locator('[data-pw-skill-input="0"]')).toHaveValue('TypeScript')
  })

  test('nested array field operations - items with tags', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')

    // Fill required fields
    await nameInput.fill('John Doe')
    await emailInput.fill('john@example.com')

    // Add an item
    await page.locator('[data-pw-add-item]').click()
    await expect(page.locator('[data-pw-item]')).toHaveCount(1)

    // Fill item title
    await page.locator('[data-pw-item-title="0"]').fill('First Item')

    // Add tags to the item
    await page.locator('[data-pw-add-tag="0"]').click()
    await page.locator('[data-pw-add-tag="0"]').click()
    await expect(page.locator('[data-pw-tag-item]')).toHaveCount(2)

    // Fill tags
    await page.locator('[data-pw-tag-input="0-0"]').fill('important')
    await page.locator('[data-pw-tag-input="0-1"]').fill('urgent')

    // Add second item
    await page.locator('[data-pw-add-item]').click()
    await expect(page.locator('[data-pw-item]')).toHaveCount(2)

    // Fill second item
    await page.locator('[data-pw-item-title="1"]').fill('Second Item')
    await page.locator('[data-pw-add-tag="1"]').click()
    await page.locator('[data-pw-tag-input="1-0"]').fill('normal')

    // Remove first tag from first item
    await page.locator('[data-pw-remove-tag="0-0"]').click()

    // Should have one tag left in first item
    const firstItemTags = page.locator('[data-pw-item="0"] [data-pw-tag-item]')
    await expect(firstItemTags).toHaveCount(1)
    await expect(page.locator('[data-pw-tag-input="0-0"]')).toHaveValue('urgent')

    // Remove first item entirely
    await page.locator('[data-pw-remove-item="0"]').click()
    await expect(page.locator('[data-pw-item]')).toHaveCount(1)

    // Remaining item should be "Second Item"
    await expect(page.locator('[data-pw-item-title="0"]')).toHaveValue('Second Item')
  })

  test('form validation lifecycle with server errors', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')
    const acceptTermsCheckbox = page.locator('[data-pw-accept-terms]')

    // Fill invalid data that will trigger server validation
    await nameInput.fill('A') // Too short
    await emailInput.fill('invalid-email') // Invalid format
    await nameInput.blur()
    await emailInput.blur()
    await acceptTermsCheckbox.check()
    await syncLV(page)

    // Should show validation errors
    await expect(page.locator('[data-pw-name-error]')).toBeVisible()
    await expect(page.locator('[data-pw-email-error]')).toBeVisible()
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: false')

    // Fix the name
    await nameInput.fill('John Doe')
    await nameInput.blur()
    await syncLV(page)

    // Name error should be gone, email error should remain
    await expect(page.locator('[data-pw-name-error]')).not.toBeVisible()
    await expect(page.locator('[data-pw-email-error]')).toBeVisible()
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: false')

    // Fix the email
    await emailInput.fill('john@example.com')
    await emailInput.blur()
    await syncLV(page)

    // All errors should be gone
    await expect(page.locator('[data-pw-name-error]')).not.toBeVisible()
    await expect(page.locator('[data-pw-email-error]')).not.toBeVisible()
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: true')
  })

  test('form submission with valid data', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')
    const ageInput = page.locator('[data-pw-age-input]')
    const bioInput = page.locator('[data-pw-bio-input]')
    const acceptTermsCheckbox = page.locator('[data-pw-accept-terms]')

    // Fill valid form data
    await nameInput.fill('John Doe')
    await emailInput.fill('john@example.com')
    await ageInput.fill('30')
    await bioInput.fill('This is a comprehensive bio with sufficient content for validation')
    await acceptTermsCheckbox.check()
    // let's wait for the debounce to finish
    await page.waitForTimeout(150)
    await syncLV(page)

    // Add some skills
    await page.locator('[data-pw-add-skill]').click()
    await page.locator('[data-pw-skill-input="0"]').fill('JavaScript')
    await page.locator('[data-pw-add-skill]').click()
    await page.locator('[data-pw-skill-input="1"]').fill('Vue.js')

    // Add an item with tags
    await page.locator('[data-pw-add-item]').click()
    await page.locator('[data-pw-item-title="0"]').fill('Build awesome apps')
    await page.locator('[data-pw-add-tag="0"]').click()
    await page.locator('[data-pw-tag-input="0-0"]').fill('development')

    await syncLV(page)

    // Form should be valid
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: true')
    await expect(page.locator('[data-pw-submit]')).toBeEnabled()

    // Submit the form
    await page.locator('[data-pw-submit]').click()
    await syncLV(page)

    // Form should be reset after successful submission
    await expect(page.locator('[data-pw-name-input]')).toHaveValue('')
    await expect(page.locator('[data-pw-email-input]')).toHaveValue('')
    await expect(page.locator('[data-pw-is-dirty]')).toHaveText('Dirty: false')
    await expect(page.locator('[data-pw-is-touched]')).toHaveText('Touched: false')
  })

  test('form reset functionality', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')

    // Fill some data
    await nameInput.fill('John Doe')
    await emailInput.fill('john@example.com')
    await page.locator('[data-pw-add-skill]').click()
    await page.locator('[data-pw-skill-input="0"]').fill('JavaScript')

    await syncLV(page)

    // Form should be dirty
    await expect(page.locator('[data-pw-is-dirty]')).toHaveText('Dirty: true')

    // Reset the form
    await page.locator('[data-pw-reset]').click()

    // Form should be clean
    await expect(page.locator('[data-pw-name-input]')).toHaveValue('')
    await expect(page.locator('[data-pw-email-input]')).toHaveValue('')
    await expect(page.locator('[data-pw-skill-item]')).toHaveCount(0)
    await expect(page.locator('[data-pw-is-dirty]')).toHaveText('Dirty: false')
    await expect(page.locator('[data-pw-is-touched]')).toHaveText('Touched: false')
  })

  test('debounced validation events', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')

    // Type rapidly to test debouncing
    await nameInput.focus()
    await nameInput.pressSequentially('John', { delay: 50 })

    // Should not trigger validation immediately
    await page.waitForTimeout(100)

    // Continue typing
    await nameInput.pressSequentially(' Doe', { delay: 50 })

    // Wait for debounce period (300ms) plus some buffer
    await page.waitForTimeout(400)
    await syncLV(page)

    // Should have final value and validation should have occurred
    await expect(nameInput).toHaveValue('John Doe')
    await expect(page.locator('[data-pw-is-dirty]')).toHaveText('Dirty: true')
  })

  test('accessibility attributes are properly set', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')

    // Fill invalid data to trigger errors
    await nameInput.fill('A')
    await emailInput.fill('invalid')
    await nameInput.blur()
    await emailInput.blur()
    await syncLV(page)

    // Check aria-invalid attributes
    await expect(nameInput).toHaveAttribute('aria-invalid', 'true')
    await expect(emailInput).toHaveAttribute('aria-invalid', 'true')

    // Check aria-describedby attributes
    await expect(nameInput).toHaveAttribute('aria-describedby')
    await expect(emailInput).toHaveAttribute('aria-describedby')

    // Fix the errors
    await nameInput.fill('John Doe')
    await emailInput.fill('john@example.com')
    await nameInput.blur()
    await emailInput.blur()
    await syncLV(page)

    // Aria-invalid should be false
    await expect(nameInput).toHaveAttribute('aria-invalid', 'false')
    await expect(emailInput).toHaveAttribute('aria-invalid', 'false')
  })

  test('form maintains state during LiveView updates', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')

    // Start filling the form
    await nameInput.focus()
    await nameInput.fill('John')

    // Trigger a server action that might update the form
    await emailInput.fill('john@example.com')
    await emailInput.blur()
    await syncLV(page)

    // Continue editing the name field while server processes
    await nameInput.focus()
    await nameInput.fill('John Doe')

    // The name field should retain the user's input
    await expect(nameInput).toHaveValue('John Doe')
    await expect(emailInput).toHaveValue('john@example.com')
  })

  test('complex nested validation with items and tags', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')
    const acceptTermsCheckbox = page.locator('[data-pw-accept-terms]')

    // Fill required fields
    await nameInput.fill('John Doe')
    await emailInput.fill('john@example.com')
    await acceptTermsCheckbox.check()

    // Add item with invalid title (too short)
    await page.locator('[data-pw-add-item]').click()
    await page.locator('[data-pw-item-title="0"]').fill('Hi') // Too short
    await page.locator('[data-pw-item-title="0"]').blur()
    await syncLV(page)

    // Form should be invalid due to item validation
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: false')

    // Fix the item title
    await page.locator('[data-pw-item-title="0"]').fill('Valid Item Title')
    await page.locator('[data-pw-item-title="0"]').blur()
    await syncLV(page)

    // Form should be valid now
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: true')

    // Add a short tag (which should be invalid)
    await page.locator('[data-pw-add-tag="0"]').click()
    await page.locator('[data-pw-tag-input="0-0"]').fill('a')
    await page.locator('[data-pw-tag-input="0-0"]').blur()
    await syncLV(page)

    // Form should be invalid due to short tag
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: false')

    // Fill the tag
    await page.locator('[data-pw-tag-input="0-0"]').fill('valid-tag')
    await page.locator('[data-pw-tag-input="0-0"]').blur()
    await syncLV(page)

    // Form should be valid again
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: true')
  })

  test('single checkbox functionality', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')
    const acceptTermsCheckbox = page.locator('[data-pw-accept-terms]')
    const newsletterCheckbox = page.locator('[data-pw-newsletter]')

    // Fill required fields first
    await nameInput.fill('John Doe')
    await emailInput.fill('john@example.com')
    await syncLV(page)

    // Initially checkboxes should be unchecked
    await expect(acceptTermsCheckbox).not.toBeChecked()
    await expect(newsletterCheckbox).not.toBeChecked()

    // Form should be invalid because acceptTerms is required
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: false')

    // Check accept terms
    await acceptTermsCheckbox.check()
    await syncLV(page)

    // Form should now be valid
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: true')
    await expect(acceptTermsCheckbox).toBeChecked()
    await expect(newsletterCheckbox).not.toBeChecked()

    // Check newsletter (optional)
    await newsletterCheckbox.check()
    await syncLV(page)

    // Form should still be valid, both checkboxes checked
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: true')
    await expect(acceptTermsCheckbox).toBeChecked()
    await expect(newsletterCheckbox).toBeChecked()

    // Uncheck accept terms - form should become invalid
    await acceptTermsCheckbox.uncheck()
    await syncLV(page)

    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: false')
    await expect(acceptTermsCheckbox).not.toBeChecked()
    await expect(newsletterCheckbox).toBeChecked()

    // Should show error message for accept terms
    await expect(page.locator('[data-pw-accept-terms-error]')).toBeVisible()
  })

  test('multi-checkbox array functionality', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')
    const acceptTermsCheckbox = page.locator('[data-pw-accept-terms]')
    const emailPrefCheckbox = page.locator('[data-pw-preferences-email]')
    const smsPrefCheckbox = page.locator('[data-pw-preferences-sms]')
    const pushPrefCheckbox = page.locator('[data-pw-preferences-push]')

    // Fill required fields
    await nameInput.fill('John Doe')
    await emailInput.fill('john@example.com')
    await acceptTermsCheckbox.check()
    await syncLV(page)

    // Initially all preference checkboxes should be unchecked
    await expect(emailPrefCheckbox).not.toBeChecked()
    await expect(smsPrefCheckbox).not.toBeChecked()
    await expect(pushPrefCheckbox).not.toBeChecked()

    // Check email preference
    await emailPrefCheckbox.check()
    await syncLV(page)

    await expect(emailPrefCheckbox).toBeChecked()
    await expect(smsPrefCheckbox).not.toBeChecked()
    await expect(pushPrefCheckbox).not.toBeChecked()

    // Check SMS preference as well
    await smsPrefCheckbox.check()
    await syncLV(page)

    await expect(emailPrefCheckbox).toBeChecked()
    await expect(smsPrefCheckbox).toBeChecked()
    await expect(pushPrefCheckbox).not.toBeChecked()

    // Check all preferences
    await pushPrefCheckbox.check()
    await syncLV(page)

    await expect(emailPrefCheckbox).toBeChecked()
    await expect(smsPrefCheckbox).toBeChecked()
    await expect(pushPrefCheckbox).toBeChecked()

    // Uncheck middle one (SMS)
    await smsPrefCheckbox.uncheck()
    await syncLV(page)

    await expect(emailPrefCheckbox).toBeChecked()
    await expect(smsPrefCheckbox).not.toBeChecked()
    await expect(pushPrefCheckbox).toBeChecked()

    // Uncheck all
    await emailPrefCheckbox.uncheck()
    await pushPrefCheckbox.uncheck()
    await syncLV(page)

    await expect(emailPrefCheckbox).not.toBeChecked()
    await expect(smsPrefCheckbox).not.toBeChecked()
    await expect(pushPrefCheckbox).not.toBeChecked()
  })

  test('checkbox state persistence during form operations', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')
    const acceptTermsCheckbox = page.locator('[data-pw-accept-terms]')
    const newsletterCheckbox = page.locator('[data-pw-newsletter]')
    const emailPrefCheckbox = page.locator('[data-pw-preferences-email]')
    const smsPrefCheckbox = page.locator('[data-pw-preferences-sms]')

    // Fill form with valid data and check some boxes
    await nameInput.fill('John Doe')
    await emailInput.fill('john@example.com')
    await acceptTermsCheckbox.check()
    await newsletterCheckbox.check()
    await emailPrefCheckbox.check()
    await smsPrefCheckbox.check()
    await syncLV(page)

    // Verify all are checked
    await expect(acceptTermsCheckbox).toBeChecked()
    await expect(newsletterCheckbox).toBeChecked()
    await expect(emailPrefCheckbox).toBeChecked()
    await expect(smsPrefCheckbox).toBeChecked()

    // Add some dynamic content (array items) to trigger more server updates
    await page.locator('[data-pw-add-skill]').click()
    await page.locator('[data-pw-skill-input="0"]').fill('JavaScript')
    await syncLV(page)

    // Checkbox states should be preserved
    await expect(acceptTermsCheckbox).toBeChecked()
    await expect(newsletterCheckbox).toBeChecked()
    await expect(emailPrefCheckbox).toBeChecked()
    await expect(smsPrefCheckbox).toBeChecked()

    // Make some changes to trigger validation
    await nameInput.fill('J') // Too short, will cause validation error
    await nameInput.blur()
    await syncLV(page)

    // Checkbox states should still be preserved even with validation errors
    await expect(acceptTermsCheckbox).toBeChecked()
    await expect(newsletterCheckbox).toBeChecked()
    await expect(emailPrefCheckbox).toBeChecked()
    await expect(smsPrefCheckbox).toBeChecked()

    // Fix the name
    await nameInput.fill('John Doe')
    await nameInput.blur()
    await syncLV(page)

    // Checkbox states should still be preserved
    await expect(acceptTermsCheckbox).toBeChecked()
    await expect(newsletterCheckbox).toBeChecked()
    await expect(emailPrefCheckbox).toBeChecked()
    await expect(smsPrefCheckbox).toBeChecked()
  })

  test('checkbox form reset functionality', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')
    const acceptTermsCheckbox = page.locator('[data-pw-accept-terms]')
    const newsletterCheckbox = page.locator('[data-pw-newsletter]')
    const emailPrefCheckbox = page.locator('[data-pw-preferences-email]')
    const pushPrefCheckbox = page.locator('[data-pw-preferences-push]')

    // Fill form and check boxes
    await nameInput.fill('John Doe')
    await emailInput.fill('john@example.com')
    await acceptTermsCheckbox.check()
    await newsletterCheckbox.check()
    await emailPrefCheckbox.check()
    await pushPrefCheckbox.check()
    await syncLV(page)

    // Verify everything is set
    await expect(acceptTermsCheckbox).toBeChecked()
    await expect(newsletterCheckbox).toBeChecked()
    await expect(emailPrefCheckbox).toBeChecked()
    await expect(pushPrefCheckbox).toBeChecked()
    await expect(page.locator('[data-pw-is-dirty]')).toHaveText('Dirty: true')

    // Reset the form
    await page.locator('[data-pw-reset]').click()

    // All checkboxes should be unchecked
    await expect(acceptTermsCheckbox).not.toBeChecked()
    await expect(newsletterCheckbox).not.toBeChecked()
    await expect(emailPrefCheckbox).not.toBeChecked()
    await expect(pushPrefCheckbox).not.toBeChecked()
    await expect(page.locator('[data-pw-is-dirty]')).toHaveText('Dirty: false')
  })

  test('checkbox form submission with all checkbox states', async ({ page }) => {
    const nameInput = page.locator('[data-pw-name-input]')
    const emailInput = page.locator('[data-pw-email-input]')
    const ageInput = page.locator('[data-pw-age-input]')
    const acceptTermsCheckbox = page.locator('[data-pw-accept-terms]')
    const newsletterCheckbox = page.locator('[data-pw-newsletter]')
    const emailPrefCheckbox = page.locator('[data-pw-preferences-email]')
    const smsPrefCheckbox = page.locator('[data-pw-preferences-sms]')

    // Fill form with valid data
    await nameInput.fill('John Doe')
    await emailInput.fill('john@example.com')
    await ageInput.fill('30')
    await acceptTermsCheckbox.check()
    await newsletterCheckbox.check()
    await emailPrefCheckbox.check()
    await smsPrefCheckbox.check()

    // Add bio to make form valid
    const bioInput = page.locator('[data-pw-bio-input]')
    await bioInput.fill('This is a comprehensive bio with sufficient content for validation')

    await syncLV(page)

    // Form should be valid
    await expect(page.locator('[data-pw-is-valid]')).toHaveText('Valid: true')
    await expect(page.locator('[data-pw-submit]')).toBeEnabled()

    // Submit the form
    await page.locator('[data-pw-submit]').click()
    await syncLV(page)

    // Form should be reset after successful submission
    await expect(acceptTermsCheckbox).not.toBeChecked()
    await expect(newsletterCheckbox).not.toBeChecked()
    await expect(emailPrefCheckbox).not.toBeChecked()
    await expect(smsPrefCheckbox).not.toBeChecked()
    await expect(page.locator('[data-pw-is-dirty]')).toHaveText('Dirty: false')
    await expect(page.locator('[data-pw-is-touched]')).toHaveText('Touched: false')
  })
})

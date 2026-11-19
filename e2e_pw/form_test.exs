defmodule LiveVue.E2E.FormTest do
  use LiveVue.E2E.Case, async: true

  describe "useLiveForm E2E Tests" do
    setup %{page: page} do
      Page.goto!(page, "/form-test")
      sync_lv(page)
      :ok
    end

    test "form initializes with empty state and is invalid", %{page: page} do
      # Verify form component is mounted
      Expect.to_be_visible!(Page.locator(page, "[data-pw-form]"))

      # Check initial form state
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: false")
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-dirty]"), "Dirty: false")
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-touched]"), "Touched: false")

      # Submit button should be disabled initially
      Expect.to_be_disabled!(Page.locator(page, "[data-pw-submit]"))
    end

    test "basic field validation and form state tracking", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")
      accept_terms_checkbox = Page.locator(page, "[data-pw-accept-terms]")

      # Fill name field (but not enough characters) - use type instead of fill
      Locator.type!(name_input, "A")
      Locator.blur!(name_input)
      # Give time for debounced events
      Page.wait_for_timeout!(page, 500)
      sync_lv(page)

      # Form should be touched and dirty but not valid
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-touched]"), "Touched: true")
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-dirty]"), "Dirty: true")
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: false")

      # Should show validation error after server validation
      Expect.to_be_visible!(Page.locator(page, "[data-pw-name-error]"))

      # Fill valid data
      Locator.clear!(name_input)
      Locator.type!(name_input, "John Doe")
      Locator.type!(email_input, "john@example.com")
      # Accept terms is now required
      Locator.check!(accept_terms_checkbox)
      # Give time for debounced events
      Page.wait_for_timeout!(page, 500)
      sync_lv(page)

      # Form should now be valid
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: true")
      Expect.to_be_enabled!(Page.locator(page, "[data-pw-submit]"))
    end

    test "nested field validation (profile bio)", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")
      bio_input = Page.locator(page, "[data-pw-bio-input]")
      accept_terms_checkbox = Page.locator(page, "[data-pw-accept-terms]")

      # Fill required fields first
      Locator.fill!(name_input, "John Doe")
      Locator.fill!(email_input, "john@example.com")
      Locator.check!(accept_terms_checkbox)

      # Fill bio with insufficient content
      Locator.fill!(bio_input, "Short")
      Locator.blur!(bio_input)
      sync_lv(page)

      # Should show bio validation error
      Expect.to_be_visible!(Page.locator(page, "[data-pw-bio-error]"))
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: false")

      # Fill with valid bio
      Locator.fill!(bio_input, "This is a valid bio with enough characters to pass validation")
      Locator.blur!(bio_input)
      sync_lv(page)

      # Form should be valid now
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: true")
    end

    test "array field operations - skills", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")

      # Fill required fields
      Locator.fill!(name_input, "John Doe")
      Locator.fill!(email_input, "john@example.com")

      # Initially no skills
      Expect.to_have_count!(Page.locator(page, "[data-pw-skill-item]"), 0)

      # Add a skill
      Locator.click!(Page.locator(page, "[data-pw-add-skill]"))
      Expect.to_have_count!(Page.locator(page, "[data-pw-skill-item]"), 1)

      # Fill the skill
      Locator.fill!(Page.locator(page, ~s([data-pw-skill-input="0"])), "JavaScript")
      sync_lv(page)

      # Add another skill
      Locator.click!(Page.locator(page, "[data-pw-add-skill]"))
      Expect.to_have_count!(Page.locator(page, "[data-pw-skill-item]"), 2)

      # Fill second skill
      Locator.fill!(Page.locator(page, ~s([data-pw-skill-input="1"])), "TypeScript")
      sync_lv(page)

      # Remove first skill
      Locator.click!(Page.locator(page, ~s([data-pw-remove-skill="0"])))
      Expect.to_have_count!(Page.locator(page, "[data-pw-skill-item]"), 1)

      # Remaining skill should be TypeScript
      Expect.to_have_value!(Page.locator(page, ~s([data-pw-skill-input="0"])), "TypeScript")
    end

    test "nested array field operations - items with tags", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")

      # Fill required fields
      Locator.fill!(name_input, "John Doe")
      Locator.fill!(email_input, "john@example.com")

      # Add an item
      Locator.click!(Page.locator(page, "[data-pw-add-item]"))
      Expect.to_have_count!(Page.locator(page, "[data-pw-item]"), 1)

      # Fill item title
      Locator.fill!(Page.locator(page, ~s([data-pw-item-title="0"])), "First Item")

      # Add tags to the item
      Locator.click!(Page.locator(page, ~s([data-pw-add-tag="0"])))
      Locator.click!(Page.locator(page, ~s([data-pw-add-tag="0"])))
      Expect.to_have_count!(Page.locator(page, "[data-pw-tag-item]"), 2)

      # Fill tags
      Locator.fill!(Page.locator(page, ~s([data-pw-tag-input="0-0"])), "important")
      Locator.fill!(Page.locator(page, ~s([data-pw-tag-input="0-1"])), "urgent")

      # Add second item
      Locator.click!(Page.locator(page, "[data-pw-add-item]"))
      Expect.to_have_count!(Page.locator(page, "[data-pw-item]"), 2)

      # Fill second item
      Locator.fill!(Page.locator(page, ~s([data-pw-item-title="1"])), "Second Item")
      Locator.click!(Page.locator(page, ~s([data-pw-add-tag="1"])))
      Locator.fill!(Page.locator(page, ~s([data-pw-tag-input="1-0"])), "normal")

      # Remove first tag from first item
      Locator.click!(Page.locator(page, ~s([data-pw-remove-tag="0-0"])))

      # Should have one tag left in first item
      first_item_tags = Page.locator(page, ~s([data-pw-item="0"] [data-pw-tag-item]))
      Expect.to_have_count!(first_item_tags, 1)
      Expect.to_have_value!(Page.locator(page, ~s([data-pw-tag-input="0-0"])), "urgent")

      # Remove first item entirely
      Locator.click!(Page.locator(page, ~s([data-pw-remove-item="0"])))
      Expect.to_have_count!(Page.locator(page, "[data-pw-item]"), 1)

      # Remaining item should be "Second Item"
      Expect.to_have_value!(Page.locator(page, ~s([data-pw-item-title="0"])), "Second Item")
    end

    test "form validation lifecycle with server errors", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")
      accept_terms_checkbox = Page.locator(page, "[data-pw-accept-terms]")

      # Fill invalid data that will trigger server validation
      # Too short
      Locator.fill!(name_input, "A")
      # Invalid format
      Locator.fill!(email_input, "invalid-email")
      Locator.blur!(name_input)
      Locator.blur!(email_input)
      Locator.check!(accept_terms_checkbox)
      sync_lv(page)

      # Should show validation errors
      Expect.to_be_visible!(Page.locator(page, "[data-pw-name-error]"))
      Expect.to_be_visible!(Page.locator(page, "[data-pw-email-error]"))
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: false")

      # Fix the name
      Locator.fill!(name_input, "John Doe")
      Locator.blur!(name_input)
      sync_lv(page)

      # Name error should be gone, email error should remain
      page |> Page.locator("[data-pw-name-error]") |> Expect.not_() |> Expect.to_be_visible!()
      Expect.to_be_visible!(Page.locator(page, "[data-pw-email-error]"))
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: false")

      # Fix the email
      Locator.fill!(email_input, "john@example.com")
      Locator.blur!(email_input)
      sync_lv(page)

      # All errors should be gone
      page |> Page.locator("[data-pw-name-error]") |> Expect.not_() |> Expect.to_be_visible!()
      page |> Page.locator("[data-pw-email-error]") |> Expect.not_() |> Expect.to_be_visible!()
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: true")
    end

    test "form submission with valid data", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")
      age_input = Page.locator(page, "[data-pw-age-input]")
      bio_input = Page.locator(page, "[data-pw-bio-input]")
      accept_terms_checkbox = Page.locator(page, "[data-pw-accept-terms]")

      # Fill valid form data
      Locator.fill!(name_input, "John Doe")
      Locator.fill!(email_input, "john@example.com")
      Locator.fill!(age_input, "30")
      Locator.fill!(bio_input, "This is a comprehensive bio with sufficient content for validation")
      Locator.check!(accept_terms_checkbox)
      # let's wait for the debounce to finish
      Page.wait_for_timeout!(page, 150)
      sync_lv(page)

      # Add some skills
      Locator.click!(Page.locator(page, "[data-pw-add-skill]"))
      Locator.fill!(Page.locator(page, ~s([data-pw-skill-input="0"])), "JavaScript")
      Locator.click!(Page.locator(page, "[data-pw-add-skill]"))
      Locator.fill!(Page.locator(page, ~s([data-pw-skill-input="1"])), "Vue.js")

      # Add an item with tags
      Locator.click!(Page.locator(page, "[data-pw-add-item]"))
      Locator.fill!(Page.locator(page, ~s([data-pw-item-title="0"])), "Build awesome apps")
      Locator.click!(Page.locator(page, ~s([data-pw-add-tag="0"])))
      Locator.fill!(Page.locator(page, ~s([data-pw-tag-input="0-0"])), "development")

      sync_lv(page)

      # Form should be valid
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: true")
      Expect.to_be_enabled!(Page.locator(page, "[data-pw-submit]"))

      # Submit the form
      Locator.click!(Page.locator(page, "[data-pw-submit]"))
      sync_lv(page)

      # Form should be reset after successful submission
      Expect.to_have_value!(Page.locator(page, "[data-pw-name-input]"), "")
      Expect.to_have_value!(Page.locator(page, "[data-pw-email-input]"), "")
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-dirty]"), "Dirty: false")
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-touched]"), "Touched: false")
    end

    test "form reset functionality", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")

      # Fill some data
      Locator.fill!(name_input, "John Doe")
      Locator.fill!(email_input, "john@example.com")
      Locator.click!(Page.locator(page, "[data-pw-add-skill]"))
      Locator.fill!(Page.locator(page, ~s([data-pw-skill-input="0"])), "JavaScript")

      sync_lv(page)

      # Form should be dirty
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-dirty]"), "Dirty: true")

      # Reset the form
      Locator.click!(Page.locator(page, "[data-pw-reset]"))

      # Form should be clean
      Expect.to_have_value!(Page.locator(page, "[data-pw-name-input]"), "")
      Expect.to_have_value!(Page.locator(page, "[data-pw-email-input]"), "")
      Expect.to_have_count!(Page.locator(page, "[data-pw-skill-item]"), 0)
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-dirty]"), "Dirty: false")
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-touched]"), "Touched: false")
    end

    test "debounced validation events", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")

      # Type rapidly to test debouncing
      Locator.focus!(name_input)
      Locator.press_sequentially!(name_input, "John", delay: 50)

      # Should not trigger validation immediately
      Page.wait_for_timeout!(page, 100)

      # Continue typing
      Locator.press_sequentially!(name_input, " Doe", delay: 50)

      # Wait for debounce period (300ms) plus some buffer
      Page.wait_for_timeout!(page, 400)
      sync_lv(page)

      # Should have final value and validation should have occurred
      Expect.to_have_value!(name_input, "John Doe")
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-dirty]"), "Dirty: true")
    end

    test "accessibility attributes are properly set", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")

      # Fill invalid data to trigger errors
      Locator.fill!(name_input, "A")
      Locator.fill!(email_input, "invalid")
      Locator.blur!(name_input)
      Locator.blur!(email_input)
      sync_lv(page)

      # Check aria-invalid attributes
      Expect.to_have_attribute!(name_input, "aria-invalid", "true")
      Expect.to_have_attribute!(email_input, "aria-invalid", "true")

      # Check aria-describedby attributes
      Expect.to_have_attribute!(name_input, "aria-describedby")
      Expect.to_have_attribute!(email_input, "aria-describedby")

      # Fix the errors
      Locator.fill!(name_input, "John Doe")
      Locator.fill!(email_input, "john@example.com")
      Locator.blur!(name_input)
      Locator.blur!(email_input)
      sync_lv(page)

      # Aria-invalid should be false
      Expect.to_have_attribute!(name_input, "aria-invalid", "false")
      Expect.to_have_attribute!(email_input, "aria-invalid", "false")
    end

    test "form maintains state during LiveView updates", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")

      # Start filling the form
      Locator.focus!(name_input)
      Locator.fill!(name_input, "John")

      # Trigger a server action that might update the form
      Locator.fill!(email_input, "john@example.com")
      Locator.blur!(email_input)
      sync_lv(page)

      # Continue editing the name field while server processes
      Locator.focus!(name_input)
      Locator.fill!(name_input, "John Doe")

      # The name field should retain the user's input
      Expect.to_have_value!(name_input, "John Doe")
      Expect.to_have_value!(email_input, "john@example.com")
    end

    test "complex nested validation with items and tags", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")
      accept_terms_checkbox = Page.locator(page, "[data-pw-accept-terms]")

      # Fill required fields
      Locator.fill!(name_input, "John Doe")
      Locator.fill!(email_input, "john@example.com")
      Locator.check!(accept_terms_checkbox)

      # Add item with invalid title (too short)
      Locator.click!(Page.locator(page, "[data-pw-add-item]"))
      # Too short
      Locator.fill!(Page.locator(page, ~s([data-pw-item-title="0"])), "Hi")
      Locator.blur!(Page.locator(page, ~s([data-pw-item-title="0"])))
      sync_lv(page)

      # Form should be invalid due to item validation
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: false")

      # Fix the item title
      Locator.fill!(Page.locator(page, ~s([data-pw-item-title="0"])), "Valid Item Title")
      Locator.blur!(Page.locator(page, ~s([data-pw-item-title="0"])))
      sync_lv(page)

      # Form should be valid now
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: true")

      # Add a short tag (which should be invalid)
      Locator.click!(Page.locator(page, ~s([data-pw-add-tag="0"])))
      Locator.fill!(Page.locator(page, ~s([data-pw-tag-input="0-0"])), "a")
      Locator.blur!(Page.locator(page, ~s([data-pw-tag-input="0-0"])))
      sync_lv(page)

      # Form should be invalid due to short tag
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: false")

      # Fill the tag
      Locator.fill!(Page.locator(page, ~s([data-pw-tag-input="0-0"])), "valid-tag")
      Locator.blur!(Page.locator(page, ~s([data-pw-tag-input="0-0"])))
      sync_lv(page)

      # Form should be valid again
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: true")
    end

    test "single checkbox functionality", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")
      accept_terms_checkbox = Page.locator(page, "[data-pw-accept-terms]")
      newsletter_checkbox = Page.locator(page, "[data-pw-newsletter]")

      # Fill required fields first
      Locator.fill!(name_input, "John Doe")
      Locator.fill!(email_input, "john@example.com")
      sync_lv(page)

      # Initially checkboxes should be unchecked
      accept_terms_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      newsletter_checkbox |> Expect.not_() |> Expect.to_be_checked!()

      # Form should be invalid because acceptTerms is required
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: false")

      # Check accept terms
      Locator.check!(accept_terms_checkbox)
      sync_lv(page)

      # Form should now be valid
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: true")
      Expect.to_be_checked!(accept_terms_checkbox)
      newsletter_checkbox |> Expect.not_() |> Expect.to_be_checked!()

      # Check newsletter (optional)
      Locator.check!(newsletter_checkbox)
      sync_lv(page)

      # Form should still be valid, both checkboxes checked
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: true")
      Expect.to_be_checked!(accept_terms_checkbox)
      Expect.to_be_checked!(newsletter_checkbox)

      # Uncheck accept terms - form should become invalid
      Locator.uncheck!(accept_terms_checkbox)
      sync_lv(page)

      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: false")
      accept_terms_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      Expect.to_be_checked!(newsletter_checkbox)

      # Should show error message for accept terms
      Expect.to_be_visible!(Page.locator(page, "[data-pw-accept-terms-error]"))
    end

    test "multi-checkbox array functionality", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")
      accept_terms_checkbox = Page.locator(page, "[data-pw-accept-terms]")
      email_pref_checkbox = Page.locator(page, "[data-pw-preferences-email]")
      sms_pref_checkbox = Page.locator(page, "[data-pw-preferences-sms]")
      push_pref_checkbox = Page.locator(page, "[data-pw-preferences-push]")

      sync_debounced_form = fn ->
        Page.wait_for_timeout!(page, 350)
        sync_lv(page)
      end

      # Fill required fields
      Locator.fill!(name_input, "John Doe")
      Locator.fill!(email_input, "john@example.com")
      Locator.check!(accept_terms_checkbox)
      sync_lv(page)

      # Initially all preference checkboxes should be unchecked
      email_pref_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      sms_pref_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      push_pref_checkbox |> Expect.not_() |> Expect.to_be_checked!()

      # Check email preference
      Locator.check!(email_pref_checkbox)
      sync_debounced_form.()

      Expect.to_be_checked!(email_pref_checkbox)
      sms_pref_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      push_pref_checkbox |> Expect.not_() |> Expect.to_be_checked!()

      # Check SMS preference as well
      Locator.check!(sms_pref_checkbox)
      sync_debounced_form.()

      Expect.to_be_checked!(email_pref_checkbox)
      Expect.to_be_checked!(sms_pref_checkbox)
      push_pref_checkbox |> Expect.not_() |> Expect.to_be_checked!()

      # Check all preferences
      Locator.check!(push_pref_checkbox)
      sync_debounced_form.()

      Expect.to_be_checked!(email_pref_checkbox)
      Expect.to_be_checked!(sms_pref_checkbox)
      Expect.to_be_checked!(push_pref_checkbox)

      # Uncheck middle one (SMS)
      Locator.uncheck!(sms_pref_checkbox)
      sync_debounced_form.()

      Expect.to_be_checked!(email_pref_checkbox)
      sms_pref_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      Expect.to_be_checked!(push_pref_checkbox)

      # Uncheck all
      Locator.uncheck!(email_pref_checkbox)
      Locator.uncheck!(push_pref_checkbox)
      sync_debounced_form.()

      email_pref_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      sms_pref_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      push_pref_checkbox |> Expect.not_() |> Expect.to_be_checked!()
    end

    test "checkbox state persistence during form operations", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")
      accept_terms_checkbox = Page.locator(page, "[data-pw-accept-terms]")
      newsletter_checkbox = Page.locator(page, "[data-pw-newsletter]")
      email_pref_checkbox = Page.locator(page, "[data-pw-preferences-email]")
      sms_pref_checkbox = Page.locator(page, "[data-pw-preferences-sms]")

      # Fill form with valid data and check some boxes
      Locator.fill!(name_input, "John Doe")
      Locator.fill!(email_input, "john@example.com")
      Locator.check!(accept_terms_checkbox)
      Locator.check!(newsletter_checkbox)
      Locator.check!(email_pref_checkbox)
      Locator.check!(sms_pref_checkbox)
      sync_lv(page)

      # Verify all are checked
      Expect.to_be_checked!(accept_terms_checkbox)
      Expect.to_be_checked!(newsletter_checkbox)
      Expect.to_be_checked!(email_pref_checkbox)
      Expect.to_be_checked!(sms_pref_checkbox)

      # Add some dynamic content (array items) to trigger more server updates
      Locator.click!(Page.locator(page, "[data-pw-add-skill]"))
      Locator.fill!(Page.locator(page, ~s([data-pw-skill-input="0"])), "JavaScript")
      sync_lv(page)

      # Checkbox states should be preserved
      Expect.to_be_checked!(accept_terms_checkbox)
      Expect.to_be_checked!(newsletter_checkbox)
      Expect.to_be_checked!(email_pref_checkbox)
      Expect.to_be_checked!(sms_pref_checkbox)

      # Make some changes to trigger validation
      # Too short, will cause validation error
      Locator.fill!(name_input, "J")
      Locator.blur!(name_input)
      sync_lv(page)

      # Checkbox states should still be preserved even with validation errors
      Expect.to_be_checked!(accept_terms_checkbox)
      Expect.to_be_checked!(newsletter_checkbox)
      Expect.to_be_checked!(email_pref_checkbox)
      Expect.to_be_checked!(sms_pref_checkbox)

      # Fix the name
      Locator.fill!(name_input, "John Doe")
      Locator.blur!(name_input)
      sync_lv(page)

      # Checkbox states should still be preserved
      Expect.to_be_checked!(accept_terms_checkbox)
      Expect.to_be_checked!(newsletter_checkbox)
      Expect.to_be_checked!(email_pref_checkbox)
      Expect.to_be_checked!(sms_pref_checkbox)
    end

    test "checkbox form reset functionality", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")
      accept_terms_checkbox = Page.locator(page, "[data-pw-accept-terms]")
      newsletter_checkbox = Page.locator(page, "[data-pw-newsletter]")
      email_pref_checkbox = Page.locator(page, "[data-pw-preferences-email]")
      push_pref_checkbox = Page.locator(page, "[data-pw-preferences-push]")

      # Fill form and check boxes
      Locator.fill!(name_input, "John Doe")
      Locator.fill!(email_input, "john@example.com")
      Locator.check!(accept_terms_checkbox)
      Locator.check!(newsletter_checkbox)
      Locator.check!(email_pref_checkbox)
      Locator.check!(push_pref_checkbox)
      sync_lv(page)

      # Verify everything is set
      Expect.to_be_checked!(accept_terms_checkbox)
      Expect.to_be_checked!(newsletter_checkbox)
      Expect.to_be_checked!(email_pref_checkbox)
      Expect.to_be_checked!(push_pref_checkbox)
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-dirty]"), "Dirty: true")

      # Reset the form
      Locator.click!(Page.locator(page, "[data-pw-reset]"))

      # All checkboxes should be unchecked
      accept_terms_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      newsletter_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      email_pref_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      push_pref_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-dirty]"), "Dirty: false")
    end

    test "checkbox form submission with all checkbox states", %{page: page} do
      name_input = Page.locator(page, "[data-pw-name-input]")
      email_input = Page.locator(page, "[data-pw-email-input]")
      age_input = Page.locator(page, "[data-pw-age-input]")
      accept_terms_checkbox = Page.locator(page, "[data-pw-accept-terms]")
      newsletter_checkbox = Page.locator(page, "[data-pw-newsletter]")
      email_pref_checkbox = Page.locator(page, "[data-pw-preferences-email]")
      sms_pref_checkbox = Page.locator(page, "[data-pw-preferences-sms]")

      # Fill form with valid data
      Locator.fill!(name_input, "John Doe")
      Locator.fill!(email_input, "john@example.com")
      Locator.fill!(age_input, "30")
      Locator.check!(accept_terms_checkbox)
      Locator.check!(newsletter_checkbox)
      Locator.check!(email_pref_checkbox)
      Locator.check!(sms_pref_checkbox)

      # Add bio to make form valid
      bio_input = Page.locator(page, "[data-pw-bio-input]")
      Locator.fill!(bio_input, "This is a comprehensive bio with sufficient content for validation")

      sync_lv(page)

      # Form should be valid
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-valid]"), "Valid: true")
      Expect.to_be_enabled!(Page.locator(page, "[data-pw-submit]"))

      # Submit the form
      Locator.click!(Page.locator(page, "[data-pw-submit]"))
      sync_lv(page)

      # Form should be reset after successful submission
      accept_terms_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      newsletter_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      email_pref_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      sms_pref_checkbox |> Expect.not_() |> Expect.to_be_checked!()
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-dirty]"), "Dirty: false")
      Expect.to_have_text!(Page.locator(page, "[data-pw-is-touched]"), "Touched: false")
    end
  end
end

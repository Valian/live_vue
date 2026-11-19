defmodule LiveVue.E2E.BasicTest do
  use LiveVue.E2E.Case, async: true

  describe "LiveVue Basic E2E Tests" do
    test "renders Vue component inside LiveView and handles increment events", %{page: page} do
      Page.goto!(page, "/test")
      sync_lv(page)

      # Verify Vue component is mounted and displays initial count
      Expect.to_be_visible!(Page.locator(page, ~s([phx-hook="VueHook"])))
      Expect.to_have_text!(Page.locator(page, "[data-pw-counter]"), "0")

      # Verify the diff slider is present and has default value
      diff_slider = Page.locator(page, ~s(input[type="range"]))
      Expect.to_be_visible!(diff_slider)
      Expect.to_have_value!(diff_slider, "1")

      # Test incrementing by default value (1)
      Locator.click!(Page.locator(page, "button"))
      sync_lv(page)
      Expect.to_have_text!(Page.locator(page, ~s([phx-hook="VueHook"] [data-pw-counter])), "1")

      # Test incrementing by a different value (3)
      Locator.fill!(diff_slider, "3")
      Locator.click!(Page.locator(page, "button"))
      sync_lv(page)
      Expect.to_have_text!(Page.locator(page, ~s([phx-hook="VueHook"] [data-pw-counter])), "4")

      # Test incrementing by maximum value (10)
      Locator.fill!(diff_slider, "10")
      Locator.click!(Page.locator(page, "button"))
      sync_lv(page)
      Expect.to_have_text!(Page.locator(page, ~s([phx-hook="VueHook"] [data-pw-counter])), "14")
    end
  end
end

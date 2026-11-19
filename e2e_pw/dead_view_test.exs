defmodule LiveVue.E2E.DeadViewTest do
  use LiveVue.E2E.Case, async: true

  alias Playwright.Response

  describe "LiveVue Dead View Tests" do
    test "renders Vue component inside regular Phoenix controller view (dead view)", %{page: page} do
      # Navigate to the dead view page
      response = Page.goto!(page, "/dead-view")

      # First check if the page loaded successfully (no 500 error)
      assert Response.status(response) == 200

      # Verify the server-rendered content from the controller
      Expect.to_have_text!(Page.locator(page, "[data-pw-server-message]"), "Hello from dead view!")

      # Wait for Vue to initialize and hydrate the component
      # In dead views, Vue still mounts via the VueHook initialization
      Page.wait_for_timeout!(page, 500)

      # Verify the Vue component rendered correctly
      Expect.to_be_visible!(Page.locator(page, "[data-pw-dead-view]"))
      Expect.to_have_text!(Page.locator(page, "[data-pw-vue-message]"), "Hello from dead view!")
    end
  end
end

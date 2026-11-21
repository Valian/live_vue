defmodule LiveVue.E2E.PersistentLayoutTest do
  use LiveVue.E2E.Case, async: true

  defp wait_for_page(page, text) do
    Expect.to_have_text!(Page.locator(page, "[data-pw-page]"), text, timeout: 5000)
  end

  test "SSR renders the injected layout tree before hydration", %{browser: browser} do
    context = Browser.new_context!(browser, java_script_enabled: false)
    page = BrowserContext.new_page!(context)

    Page.goto!(page, "/persistent-layout/page1")

    Expect.to_have_text!(Page.locator(page, "[data-pw-layout-counter]"), "0")
    Expect.to_have_text!(Page.locator(page, "[data-pw-page]"), "page1")
    Expect.to_have_text!(Page.locator(page, "[data-pw-nested]"), "I'm nested!")
    Expect.to_contain_text!(Page.locator(page, "[data-pw-sidebar-content]"), "Sidebar")

    BrowserContext.close!(context)
  end

  test "layout state persists across push_patch navigation", %{page: page} do
    Page.goto!(page, "/persistent-layout/page1")
    sync_lv(page)
    wait_for_page(page, "page1")

    # Increment layout counter a few times
    Locator.click!(Page.locator(page, "[data-pw-layout-btn]"))
    Locator.click!(Page.locator(page, "[data-pw-layout-btn]"))
    Locator.click!(Page.locator(page, "[data-pw-layout-btn]"))
    Expect.to_have_text!(Page.locator(page, "[data-pw-layout-counter]"), "3")

    # Navigate to page2 via push_patch
    eval_lv(page, ~s|{:noreply, Phoenix.LiveView.push_patch(socket, to: "/persistent-layout/page2")}|)
    sync_lv(page)
    wait_for_page(page, "page2")

    # Layout counter should be preserved (Vue state survived navigation)
    Expect.to_have_text!(Page.locator(page, "[data-pw-layout-counter]"), "3")

    # Page component should see layout counter via slot props
    Expect.to_have_text!(Page.locator(page, "[data-pw-page-layout-count]"), "3")

    # Incrementing layout counter should update in both places
    Locator.click!(Page.locator(page, "[data-pw-layout-btn]"))
    Expect.to_have_text!(Page.locator(page, "[data-pw-layout-counter]"), "4")
    Expect.to_have_text!(Page.locator(page, "[data-pw-page-layout-count]"), "4")
  end

  test "nested injection: component injected into an injected component", %{page: page} do
    Page.goto!(page, "/persistent-layout/page1")
    sync_lv(page)
    wait_for_page(page, "page1")

    # Nested component should render inside the page component's slot
    Expect.to_have_text!(Page.locator(page, "[data-pw-nested]"), "I'm nested!")

    # Navigate — nested should survive (it's inside the persistent layout tree)
    eval_lv(page, ~s|{:noreply, Phoenix.LiveView.push_patch(socket, to: "/persistent-layout/page2")}|)
    sync_lv(page)
    wait_for_page(page, "page2")

    # Nested component should still be there
    Expect.to_have_text!(Page.locator(page, "[data-pw-nested]"), "I'm nested!", timeout: 5000)
  end

  test "named slot injection via v-inject:slotname", %{page: page} do
    Page.goto!(page, "/persistent-layout/page1")
    sync_lv(page)
    wait_for_page(page, "page1")

    # Sidebar should render in the named slot with slot props
    Expect.to_contain_text!(Page.locator(page, "[data-pw-sidebar-content]"), "Sidebar")
    Expect.to_contain_text!(Page.locator(page, "[data-pw-sidebar-content]"), "layout: 0")

    # Incrementing layout counter should update sidebar's slot props too
    Locator.click!(Page.locator(page, "[data-pw-layout-btn]"))
    Expect.to_contain_text!(Page.locator(page, "[data-pw-sidebar-content]"), "layout: 1")
  end
end

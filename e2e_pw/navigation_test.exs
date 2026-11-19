defmodule LiveVue.E2E.NavigationTest do
  use LiveVue.E2E.Case, async: true

  describe "useLiveNavigation" do
    test "should patch query params and navigate between routes", %{page: page} do
      # Start at the first navigation route
      Page.goto!(page, "/navigation/test1")
      sync_lv(page)

      # Verify initial state
      Expect.to_contain_text!(Page.locator(page, "#current-params"), ~s("page":"test1"))
      Expect.to_contain_text!(Page.locator(page, "#current-query"), "{}")

      # Test patch functionality - should update query params
      Page.click!(page, "#patch-btn")
      sync_lv(page)

      # Verify query params were updated
      Expect.to_contain_text!(Page.locator(page, "#current-query"), ~s("foo":"bar"))
      Expect.to_contain_text!(Page.locator(page, "#current-query"), ~s("timestamp"))
      # URL should still have the same page param but with query params
      Expect.to_have_url!(page, ~r"/navigation/test1\?.*foo=bar")

      # Test navigate functionality - should change to alt route
      Page.click!(page, "#navigate-btn")
      sync_lv(page)

      # Verify navigation to alt route
      Expect.to_contain_text!(Page.locator(page, "#current-params"), ~s("page":"test2"))
      Expect.to_contain_text!(Page.locator(page, "#current-query"), ~s("baz":"qux"))
      Expect.to_have_url!(page, ~r"/navigation/alt/test2\?.*baz=qux")

      # Test navigate back
      Page.click!(page, "#navigate-back-btn")
      sync_lv(page)

      # Verify navigation back to original route
      Expect.to_contain_text!(Page.locator(page, "#current-params"), ~s("page":"test1"))
      Expect.to_contain_text!(Page.locator(page, "#current-query"), "{}")
      Expect.to_have_url!(page, "/navigation/test1")
    end

    test "should handle direct route access with params", %{page: page} do
      # Test direct access to alt route with query params
      Page.goto!(page, "/navigation/alt/direct?test=value&count=42")
      sync_lv(page)

      # Verify params and query params are correctly parsed
      Expect.to_contain_text!(Page.locator(page, "#current-params"), ~s("page":"direct"))
      Expect.to_contain_text!(Page.locator(page, "#current-query"), ~s("test":"value"))
      Expect.to_contain_text!(Page.locator(page, "#current-query"), ~s("count":"42"))
    end
  end
end

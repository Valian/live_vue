defmodule LiveVue.E2E.ReconnectTest do
  use LiveVue.E2E.Case, async: true

  defp reconnect(page) do
    Page.evaluate!(page, """
    () => {
      return new Promise(resolve => {
        window.liveSocket.disconnect(() => {
          setTimeout(() => {
            window.liveSocket.connect()
            resolve()
          }, 200)
        })
      })
    }
    """)

    sync_lv(page)
  end

  describe "LiveVue Reconnect" do
    test "props are refreshed from server after socket reconnect", %{page: page} do
      Page.goto!(page, "/reconnect")
      sync_lv(page)

      # Verify initial state
      Expect.to_have_text!(Page.locator(page, "[data-pw-count]"), "0")
      Expect.to_have_text!(Page.locator(page, "[data-pw-label]"), "initial")

      # Update state — this sends a diff via data-props-diff
      Locator.click!(Page.locator(page, "button"))
      sync_lv(page)
      Expect.to_have_text!(Page.locator(page, "[data-pw-count]"), "1")
      Expect.to_have_text!(Page.locator(page, "[data-pw-label]"), "updated")

      # Disconnect and reconnect.
      # Without the fix, the stale data-props-diff from the last update
      # would be re-applied, leaving Vue showing the old state.
      reconnect(page)

      # New process mounted with initial state — Vue must reflect that
      Expect.to_have_text!(Page.locator(page, "[data-pw-count]"), "0")
      Expect.to_have_text!(Page.locator(page, "[data-pw-label]"), "initial")
    end

    test "streams are restored after socket reconnect", %{page: page} do
      Page.goto!(page, "/reconnect")
      sync_lv(page)

      # Verify initial stream: 3 items
      Expect.to_have_text!(Page.locator(page, "[data-pw-item-count]"), "3")
      Expect.to_have_text!(Page.locator(page, "[data-pw-item='1']"), "Alpha")
      Expect.to_have_text!(Page.locator(page, "[data-pw-item='2']"), "Beta")
      Expect.to_have_text!(Page.locator(page, "[data-pw-item='3']"), "Gamma")

      # Update — adds a 4th stream item
      Locator.click!(Page.locator(page, "button"))
      sync_lv(page)
      Expect.to_have_text!(Page.locator(page, "[data-pw-item-count]"), "4")
      Expect.to_have_text!(Page.locator(page, "[data-pw-item='4']"), "Delta")

      # Reconnect — new process re-mounts with only the original 3 items
      reconnect(page)

      Expect.to_have_text!(Page.locator(page, "[data-pw-item-count]"), "3")
      Expect.to_have_text!(Page.locator(page, "[data-pw-item='1']"), "Alpha")
      Expect.to_have_text!(Page.locator(page, "[data-pw-item='2']"), "Beta")
      Expect.to_have_text!(Page.locator(page, "[data-pw-item='3']"), "Gamma")
      Expect.to_have_count!(Page.locator(page, "[data-pw-item='4']"), 0)
    end
  end
end

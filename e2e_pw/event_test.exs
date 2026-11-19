defmodule LiveVue.E2E.EventTest do
  use LiveVue.E2E.Case, async: true

  describe "useLiveEvent" do
    test "should receive notification events from server", %{page: page} do
      Page.goto!(page, "/events")
      sync_lv(page)

      # Verify initial state
      Expect.to_contain_text!(Page.locator(page, "#notification-count"), "Notification Count: 0")
      Expect.to_contain_text!(Page.locator(page, "#custom-count"), "Custom Event Count: 0")

      # Send a notification event
      Page.fill!(page, "#message-input", "Hello from test!")
      Page.click!(page, "#send-notification-btn")
      sync_lv(page)

      # Verify notification event was received
      Expect.to_contain_text!(Page.locator(page, "#notification-count"), "Notification Count: 1")
      Expect.to_contain_text!(Page.locator(page, ".notification-event"), "Hello from test!")

      # Verify the message appears in both LiveView state and Vue component
      Expect.to_contain_text!(Page.locator(page, "#message-display"), "Message: Hello from test!")
      Expect.to_contain_text!(Page.locator(page, "#event-count"), "Event Count: 1")

      # Send another notification
      Page.fill!(page, "#message-input", "Second message")
      Page.click!(page, "#send-notification-btn")
      sync_lv(page)

      # Verify both notifications are received
      Expect.to_contain_text!(Page.locator(page, "#notification-count"), "Notification Count: 2")
      Expect.to_have_count!(Page.locator(page, ".notification-event"), 2)
      Expect.to_contain_text!(Locator.nth(Page.locator(page, ".notification-event"), 1), "Second message")
    end

    test "should receive custom events from server", %{page: page} do
      Page.goto!(page, "/events")
      sync_lv(page)

      # Send a custom event
      Page.fill!(page, "#custom-data-input", "Custom data payload")
      Page.click!(page, "#send-custom-btn")
      sync_lv(page)

      # Verify custom event was received
      Expect.to_contain_text!(Page.locator(page, "#custom-count"), "Custom Event Count: 1")
      Expect.to_contain_text!(Page.locator(page, ".custom-event"), "Custom data payload (count: 1)")
      Expect.to_contain_text!(Page.locator(page, "#event-count"), "Event Count: 1")

      # Send another custom event
      Page.fill!(page, "#custom-data-input", "Another payload")
      Page.click!(page, "#send-custom-btn")
      sync_lv(page)

      # Verify both custom events are received
      Expect.to_contain_text!(Page.locator(page, "#custom-count"), "Custom Event Count: 2")
      Expect.to_have_count!(Page.locator(page, ".custom-event"), 2)
      Expect.to_contain_text!(Locator.nth(Page.locator(page, ".custom-event"), 1), "Another payload (count: 2)")
    end

    test "should handle mixed notification and custom events", %{page: page} do
      Page.goto!(page, "/events")
      sync_lv(page)

      # Send notification
      Page.fill!(page, "#message-input", "Mixed test notification")
      Page.click!(page, "#send-notification-btn")
      sync_lv(page)

      # Send custom event
      Page.fill!(page, "#custom-data-input", "Mixed test custom")
      Page.click!(page, "#send-custom-btn")
      sync_lv(page)

      # Send another notification
      Page.fill!(page, "#message-input", "Second notification")
      Page.click!(page, "#send-notification-btn")
      sync_lv(page)

      # Verify all events are received correctly
      Expect.to_contain_text!(Page.locator(page, "#notification-count"), "Notification Count: 2")
      Expect.to_contain_text!(Page.locator(page, "#custom-count"), "Custom Event Count: 1")
      Expect.to_contain_text!(Page.locator(page, "#event-count"), "Event Count: 3")

      # Verify event contents
      Expect.to_contain_text!(Locator.nth(Page.locator(page, ".notification-event"), 0), "Mixed test notification")
      Expect.to_contain_text!(Locator.nth(Page.locator(page, ".custom-event"), 0), "Mixed test custom (count: 2)")
      Expect.to_contain_text!(Locator.nth(Page.locator(page, ".notification-event"), 1), "Second notification")
    end

    test "should handle rapid sequential events", %{page: page} do
      Page.goto!(page, "/events")
      sync_lv(page)

      # Send multiple events rapidly
      for i <- 1..5 do
        Page.fill!(page, "#message-input", "Rapid message #{i}")
        Page.click!(page, "#send-notification-btn")
      end

      sync_lv(page)

      # Verify all events are received
      Expect.to_contain_text!(Page.locator(page, "#notification-count"), "Notification Count: 5")
      Expect.to_have_count!(Page.locator(page, ".notification-event"), 5)
      Expect.to_contain_text!(Page.locator(page, "#event-count"), "Event Count: 5")

      # Verify first and last messages
      Expect.to_contain_text!(Locator.nth(Page.locator(page, ".notification-event"), 0), "Rapid message 1")
      Expect.to_contain_text!(Locator.nth(Page.locator(page, ".notification-event"), 4), "Rapid message 5")
    end
  end
end

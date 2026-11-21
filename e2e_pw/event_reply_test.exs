defmodule LiveVue.E2E.EventReplyTest do
  use LiveVue.E2E.Case, async: true

  describe "useEventReply E2E Tests" do
    setup %{page: page} do
      Page.goto!(page, "/event-reply-test")
      sync_lv(page)
      :ok
    end

    test "component initializes correctly", %{page: page} do
      # Verify component is mounted
      Expect.to_be_visible!(Page.locator(page, "[data-pw-event-reply-test]"))
      Expect.to_have_text!(Page.locator(page, "[data-pw-server-counter]"), "Server Counter: 0")

      # Initial state should be empty
      Expect.to_have_text!(Page.locator(page, "[data-pw-increment-loading]"), "Loading: false")
      Expect.to_have_text!(Page.locator(page, "[data-pw-increment-data]"), "Data: null")
    end

    test "increment event with reply works correctly", %{page: page} do
      # Click increment by 1
      Locator.click!(Page.locator(page, "[data-pw-increment-1]"))
      sync_lv(page)

      # Check server state updated
      Expect.to_have_text!(Page.locator(page, "[data-pw-server-counter]"), "Server Counter: 1")

      # Check client state received reply
      Expect.to_have_text!(Page.locator(page, "[data-pw-increment-loading]"), "Loading: false")
      Expect.to_contain_text!(Page.locator(page, "[data-pw-increment-data]"), ~s("counter":1))

      # Click increment by 5
      Locator.click!(Page.locator(page, "[data-pw-increment-5]"))
      sync_lv(page)

      # Check server counter is now 6
      Expect.to_have_text!(Page.locator(page, "[data-pw-server-counter]"), "Server Counter: 6")
      Expect.to_contain_text!(Page.locator(page, "[data-pw-increment-data]"), ~s("counter":6))
    end

    test "user data fetching with different IDs", %{page: page} do
      # Fetch user 1
      Locator.click!(Page.locator(page, "[data-pw-fetch-user-1]"))
      sync_lv(page)

      Expect.to_have_text!(Page.locator(page, "[data-pw-user-loading]"), "Loading: false")
      Expect.to_contain_text!(Page.locator(page, "[data-pw-user-data]"), ~s("name":"John Doe"))
      Expect.to_contain_text!(Page.locator(page, "[data-pw-user-data]"), ~s("email":"john@example.com"))

      # Fetch user 2
      Locator.click!(Page.locator(page, "[data-pw-fetch-user-2]"))
      sync_lv(page)

      Expect.to_contain_text!(Page.locator(page, "[data-pw-user-data]"), ~s("name":"Jane Smith"))
      Expect.to_contain_text!(Page.locator(page, "[data-pw-user-data]"), ~s("email":"jane@example.com"))

      # Fetch unknown user
      Locator.click!(Page.locator(page, "[data-pw-fetch-user-999]"))
      sync_lv(page)

      Expect.to_contain_text!(Page.locator(page, "[data-pw-user-data]"), ~s("name":"Unknown User"))
    end

    test "server error response handling works correctly", %{page: page} do
      # Trigger server error response
      Locator.click!(Page.locator(page, "[data-pw-trigger-error]"))
      sync_lv(page)

      # Should receive error in data (server returns error as valid response data)
      Expect.to_have_text!(Page.locator(page, "[data-pw-error-loading]"), "Loading: false")

      Expect.to_contain_text!(
        Page.locator(page, "[data-pw-error-data]"),
        ~s("error":"Something went wrong on the server")
      )
    end

    test "no parameters event works", %{page: page} do
      # Test ping without parameters
      Locator.click!(Page.locator(page, "[data-pw-ping]"))
      sync_lv(page)

      Expect.to_have_text!(Page.locator(page, "[data-pw-ping-loading]"), "Loading: false")
      Expect.to_contain_text!(Page.locator(page, "[data-pw-ping-data]"), ~s("response":"pong"))
    end

    test "different data types are handled correctly", %{page: page} do
      # Test string - now wrapped in {data: "Hello World"}
      Locator.click!(Page.locator(page, "[data-pw-test-string]"))
      sync_lv(page)
      Expect.to_contain_text!(Page.locator(page, "[data-pw-datatype-data]"), ~s("data":"Hello World"))

      # Test number - now wrapped in {data: 42}
      Locator.click!(Page.locator(page, "[data-pw-test-number]"))
      sync_lv(page)
      Expect.to_contain_text!(Page.locator(page, "[data-pw-datatype-data]"), ~s("data":42))

      # Test boolean - now wrapped in {data: true}
      Locator.click!(Page.locator(page, "[data-pw-test-boolean]"))
      sync_lv(page)
      Expect.to_contain_text!(Page.locator(page, "[data-pw-datatype-data]"), ~s("data":true))

      # Test array - now wrapped in {data: [1,2,3,"four",true]}
      Locator.click!(Page.locator(page, "[data-pw-test-array]"))
      sync_lv(page)
      Expect.to_contain_text!(Page.locator(page, "[data-pw-datatype-data]"), ~s("data":[1,2,3,"four",true]))

      # Test object - now wrapped in {data: {nested: {value: "test"}, count: 5}}
      Locator.click!(Page.locator(page, "[data-pw-test-object]"))
      sync_lv(page)
      # Check for key components since JSON key order isn't guaranteed
      object_data = Page.locator(page, "[data-pw-datatype-data]")
      Expect.to_contain_text!(object_data, ~s("data":))
      Expect.to_contain_text!(object_data, ~s("nested":{"value":"test"}))
      Expect.to_contain_text!(object_data, ~s("count":5))

      # Test null - now wrapped in {data: null}
      Locator.click!(Page.locator(page, "[data-pw-test-null]"))
      sync_lv(page)
      Expect.to_contain_text!(Page.locator(page, "[data-pw-datatype-data]"), ~s("data":null))
    end

    test "input validation with server-side logic", %{page: page} do
      # Test short input (invalid)
      Locator.click!(Page.locator(page, "[data-pw-validate-short]"))
      sync_lv(page)

      Expect.to_contain_text!(Page.locator(page, "[data-pw-validate-data]"), ~s("valid":false))
      Expect.to_contain_text!(Page.locator(page, "[data-pw-validate-data]"), ~s("error":"Input too short"))

      # Test valid input
      Locator.click!(Page.locator(page, "[data-pw-validate-valid]"))
      sync_lv(page)

      Expect.to_contain_text!(Page.locator(page, "[data-pw-validate-data]"), ~s("valid":true))
      Expect.to_contain_text!(Page.locator(page, "[data-pw-validate-data]"), ~s("message":"Input is valid"))

      # Test long input (invalid)
      Locator.click!(Page.locator(page, "[data-pw-validate-long]"))
      sync_lv(page)

      Expect.to_contain_text!(Page.locator(page, "[data-pw-validate-data]"), ~s("valid":false))
      Expect.to_contain_text!(Page.locator(page, "[data-pw-validate-data]"), ~s("error":"Input too long"))
    end

    test "cancellation functionality works", %{page: page} do
      # Start slow event
      Locator.click!(Page.locator(page, "[data-pw-start-slow]"))

      # Should be loading immediately
      Expect.to_have_text!(Page.locator(page, "[data-pw-slow-loading]"), "Loading: true")

      # Cancel before it completes
      Locator.click!(Page.locator(page, "[data-pw-cancel-slow]"))

      # Should not be loading after cancel
      Expect.to_have_text!(Page.locator(page, "[data-pw-slow-loading]"), "Loading: false")

      # Data should remain null (cancelled)
      Expect.to_have_text!(Page.locator(page, "[data-pw-slow-data]"), "Data: null")

      # Wait a bit to ensure the server response would have arrived
      Page.wait_for_timeout!(page, 500)
      sync_lv(page)

      # Data should still be null (response ignored)
      Expect.to_have_text!(Page.locator(page, "[data-pw-slow-data]"), "Data: null")
    end

    test "concurrent execution prevention works", %{page: page} do
      # Start first slow event
      Locator.click!(Page.locator(page, "[data-pw-concurrent-first]"))

      # Should be loading
      Expect.to_have_text!(Page.locator(page, "[data-pw-slow-loading]"), "Loading: true")

      # Try to start second event - should be rejected
      Locator.click!(Page.locator(page, "[data-pw-concurrent-second]"))

      # Should still show loading from first event only
      Expect.to_have_text!(Page.locator(page, "[data-pw-slow-loading]"), "Loading: true")

      # Wait for first event to complete
      Page.wait_for_timeout!(page, 1200)
      sync_lv(page)

      # Should now show completed first event
      Expect.to_have_text!(Page.locator(page, "[data-pw-slow-loading]"), "Loading: false")
      Expect.to_contain_text!(Page.locator(page, "[data-pw-slow-data]"), ~s("message":"Slow response after 1000ms"))
    end

    test "multiple different composables work independently", %{page: page} do
      # Execute multiple different events in quick succession
      Locator.click!(Page.locator(page, "[data-pw-increment-1]"))
      Locator.click!(Page.locator(page, "[data-pw-fetch-user-1]"))
      Locator.click!(Page.locator(page, "[data-pw-ping]"))

      Page.wait_for_timeout!(page, 100)

      # All should complete successfully and independently
      Expect.to_contain_text!(Page.locator(page, "[data-pw-increment-data]"), ~s("counter":1))
      Expect.to_contain_text!(Page.locator(page, "[data-pw-user-data]"), ~s("name":"John Doe"))
      Expect.to_contain_text!(Page.locator(page, "[data-pw-ping-data]"), ~s("response":"pong"))

      # All should be not loading
      Expect.to_have_text!(Page.locator(page, "[data-pw-increment-loading]"), "Loading: false")
      Expect.to_have_text!(Page.locator(page, "[data-pw-user-loading]"), "Loading: false")
      Expect.to_have_text!(Page.locator(page, "[data-pw-ping-loading]"), "Loading: false")
    end

    test "component state persists across LiveView updates", %{page: page} do
      # Execute an event to get some data
      Locator.click!(Page.locator(page, "[data-pw-increment-5]"))
      sync_lv(page)

      Expect.to_contain_text!(Page.locator(page, "[data-pw-increment-data]"), ~s("counter":5))

      # Trigger another server update that doesn't affect this composable
      Locator.click!(Page.locator(page, "[data-pw-fetch-user-1]"))
      sync_lv(page)

      # Original increment data should still be there
      Expect.to_contain_text!(Page.locator(page, "[data-pw-increment-data]"), ~s("counter":5))
      Expect.to_contain_text!(Page.locator(page, "[data-pw-user-data]"), ~s("name":"John Doe"))
    end

    test "loading states are accurate", %{page: page} do
      # All should start as not loading
      Expect.to_have_text!(Page.locator(page, "[data-pw-slow-loading]"), "Loading: false")

      # Start slow event and verify loading state immediately
      Locator.click!(Page.locator(page, "[data-pw-start-slow]"))

      # Should be loading now
      Expect.to_have_text!(Page.locator(page, "[data-pw-slow-loading]"), "Loading: true")

      # Wait for completion
      Page.wait_for_timeout!(page, 2200)
      sync_lv(page)

      # Should be done loading
      Expect.to_have_text!(Page.locator(page, "[data-pw-slow-loading]"), "Loading: false")
      Expect.to_contain_text!(Page.locator(page, "[data-pw-slow-data]"), "Slow response after 2000ms")
    end
  end
end

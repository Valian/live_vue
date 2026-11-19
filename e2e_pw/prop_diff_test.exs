defmodule LiveVue.E2E.PropDiffTest do
  use LiveVue.E2E.Case, async: true

  # Read and parse props from the page
  defp get_props(page) do
    sync_lv(page)

    props_json = Locator.text_content!(Page.locator(page, ~s([data-testid="props-json"])))
    Jason.decode!(props_json)
  end

  describe "LiveVue Prop Diff E2E Tests" do
    setup %{page: page} do
      Page.goto!(page, "/prop-diff-test")
      sync_lv(page)

      # Verify Vue component is mounted
      Expect.to_be_visible!(Page.locator(page, ~s([phx-hook="VueHook"])))
      :ok
    end

    test "initial render displays all props correctly", %{page: page} do
      # Check initial props are rendered
      props = get_props(page)

      assert props["simple_string"] == "hello"
      assert props["simple_number"] == 42
      assert props["simple_boolean"] == true
      assert props["simple_list"] == ["a", "b", "c"]
      assert props["simple_map"] == %{"key1" => "value1", "key2" => "value2"}
      assert props["nested_data"]["user"] == %{"name" => "John", "age" => 30}
      assert props["nested_data"]["settings"] == %{"theme" => "dark", "notifications" => true}

      assert props["list_of_maps"] == [
               %{"id" => 1, "name" => "Alice", "role" => "admin"},
               %{"id" => 2, "name" => "Bob", "role" => "user"}
             ]
    end

    test "simple string change is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-change-string"])))

      props = get_props(page)

      assert props["simple_string"] == "changed"
      # Other props should remain unchanged
      assert props["simple_number"] == 42
      assert props["simple_boolean"] == true
    end

    test "simple number change is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-change-number"])))

      props = get_props(page)

      assert props["simple_number"] == 99
      # Other props should remain unchanged
      assert props["simple_string"] == "hello"
      assert props["simple_boolean"] == true
    end

    test "boolean toggle is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-toggle-boolean"])))

      props = get_props(page)

      assert props["simple_boolean"] == false

      # Toggle back
      Locator.click!(Page.locator(page, ~s([data-testid="btn-toggle-boolean"])))

      props2 = get_props(page)
      assert props2["simple_boolean"] == true
    end

    test "array addition is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-add-to-list"])))

      props = get_props(page)

      assert props["simple_list"] == ["a", "b", "c", "d"]
    end

    test "array removal is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-remove-from-list"])))

      props = get_props(page)

      assert props["simple_list"] == ["b", "c"]
    end

    test "array replacement is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-replace-in-list"])))

      props = get_props(page)

      assert props["simple_list"] == ["a", "REPLACED", "c"]
    end

    test "map addition is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-add-to-map"])))

      props = get_props(page)

      assert props["simple_map"] == %{
               "key1" => "value1",
               "key2" => "value2",
               "key3" => "value3"
             }
    end

    test "map removal is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-remove-from-map"])))

      props = get_props(page)

      assert props["simple_map"] == %{"key2" => "value2"}
    end

    test "nested object property change is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-change-nested-name"])))

      props = get_props(page)

      assert props["nested_data"]["user"]["name"] == "Jane"
      # Other nested properties should remain unchanged
      assert props["nested_data"]["user"]["age"] == 30
      assert props["nested_data"]["settings"] == %{"theme" => "dark", "notifications" => true}
    end

    test "nested object number change is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-change-nested-age"])))

      props = get_props(page)

      assert props["nested_data"]["user"]["age"] == 25
      # Other properties should remain unchanged
      assert props["nested_data"]["user"]["name"] == "John"
    end

    test "adding nested property is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-add-nested-setting"])))

      props = get_props(page)

      assert props["nested_data"]["settings"] == %{
               "theme" => "dark",
               "notifications" => true,
               "language" => "en"
             }
    end

    test "setting value to nil is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-set-nil"])))

      props = get_props(page)

      assert props["simple_string"] == nil
      # Other props should remain unchanged
      assert props["simple_number"] == 42
      assert props["simple_boolean"] == true
    end

    test "adding item to list of maps is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-add-list-item"])))

      props = get_props(page)

      assert props["list_of_maps"] == [
               %{"id" => 1, "name" => "Alice", "role" => "admin"},
               %{"id" => 2, "name" => "Bob", "role" => "user"},
               %{"id" => 3, "name" => "Charlie", "role" => "guest"}
             ]
    end

    test "updating item in list of maps is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-update-list-item"])))

      props = get_props(page)

      assert props["list_of_maps"] == [
               %{"id" => 1, "name" => "Alice Updated", "role" => "admin"},
               %{"id" => 2, "name" => "Bob", "role" => "user"}
             ]
    end

    test "removing item from list of maps is applied via diff", %{page: page} do
      Locator.click!(Page.locator(page, ~s([data-testid="btn-remove-list-item"])))

      props = get_props(page)

      assert props["list_of_maps"] == [%{"id" => 1, "name" => "Alice", "role" => "admin"}]
    end

    test "multiple consecutive changes are applied correctly", %{page: page} do
      # Make multiple changes in sequence
      Locator.click!(Page.locator(page, ~s([data-testid="btn-change-string"])))
      Locator.click!(Page.locator(page, ~s([data-testid="btn-change-number"])))
      Locator.click!(Page.locator(page, ~s([data-testid="btn-add-to-list"])))
      Locator.click!(Page.locator(page, ~s([data-testid="btn-change-nested-name"])))

      props = get_props(page)

      assert props["simple_string"] == "changed"
      assert props["simple_number"] == 99
      assert props["simple_list"] == ["a", "b", "c", "d"]
      assert props["nested_data"]["user"]["name"] == "Jane"

      # Unchanged properties should remain the same
      assert props["simple_boolean"] == true
      assert props["nested_data"]["user"]["age"] == 30
    end

    test "Vue component can access all updated props reactively", %{page: page} do
      # Verify that Vue component reactively updates when props change
      initial = get_props(page)

      # Make a change
      Locator.click!(Page.locator(page, ~s([data-testid="btn-change-string"])))

      # Wait for Vue to update (should be immediate)
      updated = get_props(page)

      # Verify the change is reflected immediately in the Vue component
      assert updated["simple_string"] == "changed"
      refute updated["simple_string"] == initial["simple_string"]
    end
  end
end

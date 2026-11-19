defmodule LiveVue.E2E.StreamTest do
  use LiveVue.E2E.Case, async: true

  alias Playwright.Dialog

  setup %{page: page} do
    Page.goto!(page, "/streams")
    sync_lv(page)
    :ok
  end

  describe "LiveVue Stream Integration" do
    test "renders initial stream items", %{page: page} do
      # Check that initial items are rendered
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-1"])))
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-2"])))
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-3"])))

      # Check item content
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-1"] [data-testid="item-name"])), "Item 1")

      Expect.to_have_text!(
        Page.locator(page, ~s([data-testid="item-1"] [data-testid="item-description"])),
        "First item"
      )

      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-1"] [data-testid="item-id"])), "ID: 1")

      # Check item count
      items_heading = Page.locator(page, ~s|h3:has-text("Items")|)
      Expect.to_have_text!(items_heading, "Items (3)")
    end

    test "adds new items to stream", %{page: page} do
      # Fill form and add new item
      Page.fill!(page, ~s([data-testid="name-input"]), "New Item")
      Page.fill!(page, ~s([data-testid="description-input"]), "This is a new item")
      Page.click!(page, ~s([data-testid="add-button"]))

      sync_lv(page)

      # Check that new item appears
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-4"])))
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-4"] [data-testid="item-name"])), "New Item")

      Expect.to_have_text!(
        Page.locator(page, ~s([data-testid="item-4"] [data-testid="item-description"])),
        "This is a new item"
      )

      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-4"] [data-testid="item-id"])), "ID: 4")

      # Check updated count
      items_heading = Page.locator(page, ~s|h3:has-text("Items")|)
      Expect.to_have_text!(items_heading, "Items (4)")

      # Check that form was cleared
      Expect.to_have_value!(Page.locator(page, ~s([data-testid="name-input"])), "")
      Expect.to_have_value!(Page.locator(page, ~s([data-testid="description-input"])), "")
    end

    test "adds multiple items in sequence", %{page: page} do
      # Add first item
      Page.fill!(page, ~s([data-testid="name-input"]), "Item A")
      Page.fill!(page, ~s([data-testid="description-input"]), "Description A")
      Page.click!(page, ~s([data-testid="add-button"]))
      sync_lv(page)

      # Add second item
      Page.fill!(page, ~s([data-testid="name-input"]), "Item B")
      Page.fill!(page, ~s([data-testid="description-input"]), "Description B")
      Page.click!(page, ~s([data-testid="add-button"]))
      sync_lv(page)

      # Check both items exist
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-4"])))
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-5"])))

      # Check count
      items_heading = Page.locator(page, ~s|h3:has-text("Items")|)
      Expect.to_have_text!(items_heading, "Items (5)")
    end

    test "removes individual items from stream", %{page: page} do
      # Remove item 2
      Page.click!(page, ~s([data-testid="remove-2"]))
      sync_lv(page)

      # Check that item 2 is gone but others remain
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-1"])))
      page |> Page.locator(~s([data-testid="item-2"])) |> Expect.not_() |> Expect.to_be_visible!()
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-3"])))

      # Check updated count
      items_heading = Page.locator(page, ~s|h3:has-text("Items")|)
      Expect.to_have_text!(items_heading, "Items (2)")
    end

    test "removes multiple items", %{page: page} do
      # Remove items 1 and 3
      Page.click!(page, ~s([data-testid="remove-1"]))
      sync_lv(page)
      Page.click!(page, ~s([data-testid="remove-3"]))
      sync_lv(page)

      # Check only item 2 remains
      page |> Page.locator(~s([data-testid="item-1"])) |> Expect.not_() |> Expect.to_be_visible!()
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-2"])))
      page |> Page.locator(~s([data-testid="item-3"])) |> Expect.not_() |> Expect.to_be_visible!()

      # Check count
      items_heading = Page.locator(page, ~s|h3:has-text("Items")|)
      Expect.to_have_text!(items_heading, "Items (1)")
    end

    test "clears entire stream", %{page: page} do
      # Clear all items
      Page.click!(page, ~s([data-testid="clear-button"]))
      sync_lv(page)

      # Check that all items are gone
      page |> Page.locator(~s([data-testid="item-1"])) |> Expect.not_() |> Expect.to_be_visible!()
      page |> Page.locator(~s([data-testid="item-2"])) |> Expect.not_() |> Expect.to_be_visible!()
      page |> Page.locator(~s([data-testid="item-3"])) |> Expect.not_() |> Expect.to_be_visible!()

      # Check empty state
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="empty-message"])))
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="empty-message"])), "No items in the stream")

      # Check count
      items_heading = Page.locator(page, ~s|h3:has-text("Items")|)
      Expect.to_have_text!(items_heading, "Items (0)")
    end

    test "resets stream to default state", %{page: page} do
      # First clear the stream
      Page.click!(page, ~s([data-testid="clear-button"]))
      sync_lv(page)
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="empty-message"])))

      # Then reset it
      Page.click!(page, ~s([data-testid="reset-button"]))
      sync_lv(page)

      # Check that original items are back
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-1"])))
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-2"])))
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-3"])))
      page |> Page.locator(~s([data-testid="empty-message"])) |> Expect.not_() |> Expect.to_be_visible!()

      # Check count
      items_heading = Page.locator(page, ~s|h3:has-text("Items")|)
      Expect.to_have_text!(items_heading, "Items (3)")
    end

    test "handles complex workflow: add, remove, clear, reset", %{page: page} do
      # Add a new item
      Page.fill!(page, ~s([data-testid="name-input"]), "Workflow Item")
      Page.fill!(page, ~s([data-testid="description-input"]), "Testing workflow")
      Page.click!(page, ~s([data-testid="add-button"]))
      sync_lv(page)

      # Verify we have 4 items
      items_heading = Page.locator(page, ~s|h3:has-text("Items")|)
      Expect.to_have_text!(items_heading, "Items (4)")

      # Remove one original item
      Page.click!(page, ~s([data-testid="remove-2"]))
      sync_lv(page)
      Expect.to_have_text!(items_heading, "Items (3)")

      # Clear all
      Page.click!(page, ~s([data-testid="clear-button"]))
      sync_lv(page)
      Expect.to_have_text!(items_heading, "Items (0)")
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="empty-message"])))

      # Reset to defaults
      Page.click!(page, ~s([data-testid="reset-button"]))
      sync_lv(page)
      Expect.to_have_text!(items_heading, "Items (3)")
      page |> Page.locator(~s([data-testid="empty-message"])) |> Expect.not_() |> Expect.to_be_visible!()

      # Verify the original 3 items are back (not the added one)
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-1"])))
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-2"])))
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="item-3"])))
      page |> Page.locator(~s([data-testid="item-4"])) |> Expect.not_() |> Expect.to_be_visible!()
    end

    test "validates form input for adding items", %{page: page} do
      # Try to add item with empty name
      Page.fill!(page, ~s([data-testid="name-input"]), "")
      Page.fill!(page, ~s([data-testid="description-input"]), "Description only")

      # This should trigger an alert (form validation)
      Page.on(page, :dialog, fn dialog ->
        assert Dialog.message(dialog) == "Please enter a name for the item"
        Dialog.accept!(dialog)
      end)

      Page.click!(page, ~s([data-testid="add-button"]))

      # Item should not be added
      sync_lv(page)
      items_heading = Page.locator(page, ~s|h3:has-text("Items")|)
      # Still 3 items
      Expect.to_have_text!(items_heading, "Items (3)")
    end

    test "displays debug information correctly", %{page: page} do
      # Check debug info shows correct type and length
      Expect.to_be_visible!(Page.locator(page, ~s|.debug-info p:has-text("Items type:")|))
      Expect.to_be_visible!(Page.locator(page, ~s|.debug-info p:has-text("Items length:")|))

      # Check raw items data is displayed
      Expect.to_be_visible!(Page.locator(page, ~s([data-testid="raw-items"])))

      raw_items_text = Locator.text_content!(Page.locator(page, ~s([data-testid="raw-items"])))
      assert raw_items_text =~ ~s("id")
      assert raw_items_text =~ ~s("name")
      assert raw_items_text =~ ~s("description")
    end

    test "maintains item order during operations", %{page: page} do
      # Get initial order
      item1_name = Locator.text_content!(Page.locator(page, ~s([data-testid="item-1"] [data-testid="item-name"])))
      item2_name = Locator.text_content!(Page.locator(page, ~s([data-testid="item-2"] [data-testid="item-name"])))
      item3_name = Locator.text_content!(Page.locator(page, ~s([data-testid="item-3"] [data-testid="item-name"])))

      assert item1_name == "Item 1"
      assert item2_name == "Item 2"
      assert item3_name == "Item 3"

      # Add new item (should appear after existing ones)
      Page.fill!(page, ~s([data-testid="name-input"]), "Item 4")
      Page.fill!(page, ~s([data-testid="description-input"]), "Fourth item")
      Page.click!(page, ~s([data-testid="add-button"]))
      sync_lv(page)

      # Check that new item appears at the end
      item4_name = Locator.text_content!(Page.locator(page, ~s([data-testid="item-4"] [data-testid="item-name"])))
      assert item4_name == "Item 4"

      # Remove middle item and check order is maintained
      Page.click!(page, ~s([data-testid="remove-2"]))
      sync_lv(page)

      # Items 1, 3, 4 should still be in correct order
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-1"] [data-testid="item-name"])), "Item 1")
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-3"] [data-testid="item-name"])), "Item 3")
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-4"] [data-testid="item-name"])), "Item 4")
    end

    test "maintains correct item order after stream reset", %{page: page} do
      # Add some items and clear to modify the stream
      Page.fill!(page, ~s([data-testid="name-input"]), "Extra Item")
      Page.fill!(page, ~s([data-testid="description-input"]), "Extra description")
      Page.click!(page, ~s([data-testid="add-button"]))
      sync_lv(page)

      # Reset the stream
      Page.click!(page, ~s([data-testid="reset-button"]))
      sync_lv(page)

      # Verify items appear in correct order: Item 1, Item 2, Item 3
      all_items = Locator.all_text_contents!(Page.locator(page, ~s([data-testid="item-name"])))
      assert all_items == ["Item 1", "Item 2", "Item 3"]

      # Reset the stream
      Page.click!(page, ~s([data-testid="reset-button-at-0"]))
      sync_lv(page)

      # Verify items appear in correct order: Item 1, Item 2, Item 3
      all_reversed_items = Locator.all_text_contents!(Page.locator(page, ~s([data-testid="item-name"])))
      assert all_reversed_items == ["Item 3", "Item 2", "Item 1"]
    end
  end

  # Limit operation tests (a nested describe in the spec: its beforeEach runs after the outer one)
  describe "LiveVue Stream Integration Limit Operations" do
    setup %{page: page} do
      Page.goto!(page, "/streams")
      sync_lv(page)
      :ok
    end

    test "adds multiple items at start with positive limit", %{page: page} do
      # Verify initial state: 3 items
      Expect.to_have_text!(Page.locator(page, ~s|h3:has-text("Items")|), "Items (3)")

      # Add 3 items at start with limit 5 (should keep first 5 items)
      Page.click!(page, ~s([data-testid="add-multiple-start-button"]))
      sync_lv(page)

      # Should have 5 items total (3 new + 3 original, but limited to 5)
      Expect.to_have_text!(Page.locator(page, ~s|h3:has-text("Items")|), "Items (5)")

      # Check that new items are at the start and in correct order
      # Expected order: Start Item C, Start Item B, Start Item A, Item 1, Item 2
      # (Note: items are added at position 0 in reverse order)
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-6"] [data-testid="item-name"])), "Start Item C")
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-5"] [data-testid="item-name"])), "Start Item B")
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-4"] [data-testid="item-name"])), "Start Item A")
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-1"] [data-testid="item-name"])), "Item 1")
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-2"] [data-testid="item-name"])), "Item 2")

      # Item 3 should be removed due to limit 5
      page |> Page.locator(~s([data-testid="item-3"])) |> Expect.not_() |> Expect.to_be_visible!()
    end

    test "adds multiple items at end with negative limit", %{page: page} do
      # Verify initial state: 3 items
      Expect.to_have_text!(Page.locator(page, ~s|h3:has-text("Items")|), "Items (3)")

      # Add 3 items at end with negative limit -5 (should keep last 5 items)
      Page.click!(page, ~s([data-testid="add-multiple-end-button"]))
      sync_lv(page)

      # Should have 5 items total (3 original + 3 new, but limited to last 5)
      Expect.to_have_text!(Page.locator(page, ~s|h3:has-text("Items")|), "Items (5)")

      # Check that new items are at the end and original items remain
      # Expected order: Item 2, Item 3, End Item X, End Item Y, End Item Z
      # (Item 1 should be removed due to negative limit -5)
      page |> Page.locator(~s([data-testid="item-1"])) |> Expect.not_() |> Expect.to_be_visible!()
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-2"] [data-testid="item-name"])), "Item 2")
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-3"] [data-testid="item-name"])), "Item 3")
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-4"] [data-testid="item-name"])), "End Item X")
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-5"] [data-testid="item-name"])), "End Item Y")
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-6"] [data-testid="item-name"])), "End Item Z")
    end

    test "adds single item with custom positive limit", %{page: page} do
      # Set positive limit to 2
      Page.fill!(page, ~s([data-testid="positive-limit-input"]), "2")

      # Add item with positive limit 2
      Page.click!(page, ~s([data-testid="add-positive-limit-button"]))
      sync_lv(page)

      # Should have only 2 items (limited to first 2)
      Expect.to_have_text!(Page.locator(page, ~s|h3:has-text("Items")|), "Items (2)")

      # Check which items remain (should be original Item 1 and new limited item)
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-1"] [data-testid="item-name"])), "Item 1")

      Expect.to_have_text!(
        Page.locator(page, ~s([data-testid="item-4"] [data-testid="item-name"])),
        "Limited Item +2"
      )

      # Items 2 and 3 should be removed
      page |> Page.locator(~s([data-testid="item-2"])) |> Expect.not_() |> Expect.to_be_visible!()
      page |> Page.locator(~s([data-testid="item-3"])) |> Expect.not_() |> Expect.to_be_visible!()
    end

    test "adds single item with custom negative limit", %{page: page} do
      # Set negative limit to 2
      Page.fill!(page, ~s([data-testid="negative-limit-input"]), "2")

      # Add item with negative limit -2
      Page.click!(page, ~s([data-testid="add-negative-limit-button"]))
      sync_lv(page)

      # Should have only 2 items (limited to last 2)
      Expect.to_have_text!(Page.locator(page, ~s|h3:has-text("Items")|), "Items (2)")

      # Check which items remain (should be Item 3 and new limited item)
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-3"] [data-testid="item-name"])), "Item 3")

      Expect.to_have_text!(
        Page.locator(page, ~s([data-testid="item-4"] [data-testid="item-name"])),
        "Limited Item -2"
      )

      # Items 1 and 2 should be removed
      page |> Page.locator(~s([data-testid="item-1"])) |> Expect.not_() |> Expect.to_be_visible!()
      page |> Page.locator(~s([data-testid="item-2"])) |> Expect.not_() |> Expect.to_be_visible!()
    end

    test "handles limit operations with existing items", %{page: page} do
      # First add a regular item to have 4 items total
      Page.fill!(page, ~s([data-testid="name-input"]), "Regular Item")
      Page.fill!(page, ~s([data-testid="description-input"]), "Regular description")
      Page.click!(page, ~s([data-testid="add-button"]))
      sync_lv(page)

      # Should have 4 items
      Expect.to_have_text!(Page.locator(page, ~s|h3:has-text("Items")|), "Items (4)")

      # Now prepend with positive limit 3
      Page.fill!(page, ~s([data-testid="positive-limit-input"]), "3")
      Page.click!(page, ~s([data-testid="add-positive-limit-button"]))
      sync_lv(page)

      # Should have 3 items (first 3 kept)
      Expect.to_have_text!(Page.locator(page, ~s|h3:has-text("Items")|), "Items (3)")

      # Check that we have the first item, new regular item, and new limited item
      Expect.to_have_text!(
        Page.locator(page, ~s([data-testid="item-5"] [data-testid="item-name"])),
        "Limited Item +3"
      )

      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-1"] [data-testid="item-name"])), "Item 1")
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-2"] [data-testid="item-name"])), "Item 2")
    end

    test "validates limit input constraints", %{page: page} do
      # Test that buttons are disabled for invalid inputs
      page |> Page.locator(~s([data-testid="add-positive-limit-button"])) |> Expect.not_() |> Expect.to_be_disabled!()
      page |> Page.locator(~s([data-testid="add-negative-limit-button"])) |> Expect.not_() |> Expect.to_be_disabled!()

      # Clear inputs should disable buttons
      Page.fill!(page, ~s([data-testid="positive-limit-input"]), "")
      Page.fill!(page, ~s([data-testid="negative-limit-input"]), "")

      Expect.to_be_disabled!(Page.locator(page, ~s([data-testid="add-positive-limit-button"])))
      Expect.to_be_disabled!(Page.locator(page, ~s([data-testid="add-negative-limit-button"])))

      # Zero should disable buttons
      Page.fill!(page, ~s([data-testid="positive-limit-input"]), "0")
      Page.fill!(page, ~s([data-testid="negative-limit-input"]), "0")

      Expect.to_be_disabled!(Page.locator(page, ~s([data-testid="add-positive-limit-button"])))
      Expect.to_be_disabled!(Page.locator(page, ~s([data-testid="add-negative-limit-button"])))

      # Valid values should enable buttons
      Page.fill!(page, ~s([data-testid="positive-limit-input"]), "3")
      Page.fill!(page, ~s([data-testid="negative-limit-input"]), "3")

      page |> Page.locator(~s([data-testid="add-positive-limit-button"])) |> Expect.not_() |> Expect.to_be_disabled!()
      page |> Page.locator(~s([data-testid="add-negative-limit-button"])) |> Expect.not_() |> Expect.to_be_disabled!()
    end

    test "handles limit operations in sequence", %{page: page} do
      # Start with positive limit
      Page.fill!(page, ~s([data-testid="positive-limit-input"]), "4")
      Page.click!(page, ~s([data-testid="add-positive-limit-button"]))
      sync_lv(page)

      # Should have 4 items
      Expect.to_have_text!(Page.locator(page, ~s|h3:has-text("Items")|), "Items (4)")

      # Then apply negative limit
      Page.fill!(page, ~s([data-testid="negative-limit-input"]), "2")
      Page.click!(page, ~s([data-testid="add-negative-limit-button"]))
      sync_lv(page)

      # Should have 2 items (last 2)
      Expect.to_have_text!(Page.locator(page, ~s|h3:has-text("Items")|), "Items (2)")

      # Verify it's the limited item and one original item
      Expect.to_have_text!(Page.locator(page, ~s([data-testid="item-3"] [data-testid="item-name"])), "Item 3")

      Expect.to_have_text!(
        Page.locator(page, ~s([data-testid="item-5"] [data-testid="item-name"])),
        "Limited Item -2"
      )
    end
  end
end

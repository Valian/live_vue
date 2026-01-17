defmodule LiveVueInternalsTest do
  use ExUnit.Case

  import Phoenix.Component

  alias LiveVue.Test
  alias Phoenix.LiveView.LiveStream

  defdelegate render_vue_assigns(assigns), to: Test, as: :render_vue_component

  # Test module for Encoder protocol
  defmodule ItemWithoutId do
    @moduledoc false
    @derive LiveVue.Encoder
    defstruct [:name, :value]
  end

  defmodule ItemWithId do
    @moduledoc false
    @derive LiveVue.Encoder
    defstruct [:id, :name]
  end

  # Utility function to decode patches
  defp decode_patch(patch_list) do
    Enum.map(patch_list, fn patch ->
      case patch do
        [op, path] -> %{"op" => op, "path" => path}
        [op, path, value] -> %{"op" => op, "path" => path, "value" => value}
      end
    end)
  end

  # Utility function to assert JSON patches are equal by sorting both by path
  defp assert_patches_equal(actual, expected) do
    actual_uncompressed = decode_patch(actual)
    actual_sorted = Enum.sort_by(actual_uncompressed, & &1["path"])
    expected_sorted = Enum.sort_by(expected, & &1["path"])
    assert actual_sorted == expected_sorted
  end

  describe "object_hash/1 - when map doesn't have :id key" do
    test "returns nil for maps without id field" do
      assigns = %{
        items: [
          %{name: "Alice", value: 1},
          %{name: "Bob", value: 2}
        ],
        "v-component": "TestComponent",
        __changed__: %{}
      }

      # Reorder items - without id field, this will cause more operations
      assigns =
        assign(assigns, :items, [
          %{name: "Bob", value: 2},
          %{name: "Alice", value: 1}
        ])

      vue = render_vue_assigns(assigns)

      # Without id field, the diff algorithm treats items differently
      # It should see these as replacements rather than reordering
      expected_patches = [
        %{"op" => "replace", "path" => "/items/0/name", "value" => "Bob"},
        %{"op" => "replace", "path" => "/items/0/value", "value" => 2},
        %{"op" => "replace", "path" => "/items/1/name", "value" => "Alice"},
        %{"op" => "replace", "path" => "/items/1/value", "value" => 1}
      ]

      assert_patches_equal(vue.props_diff, expected_patches)
    end

    test "handles structs without id field" do
      assigns = %{
        items: [
          %ItemWithoutId{name: "item1", value: 10},
          %ItemWithoutId{name: "item2", value: 20}
        ],
        "v-component": "TestComponent",
        __changed__: %{}
      }

      # Change the first item
      assigns =
        assign(assigns, :items, [
          %ItemWithoutId{name: "updated", value: 15},
          %ItemWithoutId{name: "item2", value: 20}
        ])

      vue = render_vue_assigns(assigns)

      expected_patches = [
        %{"op" => "replace", "path" => "/items/0/name", "value" => "updated"},
        %{"op" => "replace", "path" => "/items/0/value", "value" => 15}
      ]

      assert_patches_equal(vue.props_diff, expected_patches)
    end

    test "with id field uses id-based diffing" do
      assigns = %{
        items: [
          %ItemWithId{id: 1, name: "Alice"},
          %ItemWithId{id: 2, name: "Bob"}
        ],
        "v-component": "TestComponent",
        __changed__: %{}
      }

      # Reorder items - with id field, this should be recognized as reordering
      assigns =
        assign(assigns, :items, [
          %ItemWithId{id: 2, name: "Bob"},
          %ItemWithId{id: 1, name: "Alice"}
        ])

      vue = render_vue_assigns(assigns)

      decoded = decode_patch(vue.props_diff)

      # With id field, reordering generates remove and add operations
      # The exact number depends on the diff algorithm implementation
      remove_ops = Enum.filter(decoded, &(&1["op"] == "remove"))
      add_ops = Enum.filter(decoded, &(&1["op"] == "add"))

      assert length(remove_ops) > 0
      assert length(add_ops) > 0
    end
  end

  describe "normalize_key/2 - :streams case for %LiveStream{}" do
    test "LiveStream values are classified as :streams" do
      stream = LiveStream.new(:users, make_ref(), [], [])

      assigns = %{
        users: stream,
        regular_prop: "value",
        "v-component": "TestComponent",
        __changed__: nil
      }

      vue = render_vue_assigns(assigns)

      # Stream should not appear in props
      assert vue.props == %{"regular_prop" => "value"}

      # Stream should be in streams_diff
      assert length(vue.streams_diff) > 0
    end

    test "multiple LiveStreams are all classified correctly" do
      users_stream = LiveStream.new(:users, make_ref(), [], [])
      posts_stream = LiveStream.new(:posts, make_ref(), [], [])

      assigns = %{
        users: users_stream,
        posts: posts_stream,
        title: "My Page",
        "v-component": "TestComponent",
        __changed__: nil
      }

      vue = render_vue_assigns(assigns)

      # Only non-stream prop should appear in props
      assert vue.props == %{"title" => "My Page"}

      # Both streams should be processed
      decoded_streams = decode_patch(vue.streams_diff)
      stream_paths = decoded_streams |> Enum.map(& &1["path"]) |> Enum.uniq()

      assert "/users" in stream_paths
      assert "/posts" in stream_paths
    end
  end

  describe "calculate_streams_diff/2 - initial == true branch" do
    test "initial render resets streams before applying diffs" do
      users = [
        %ItemWithId{id: 1, name: "Alice"},
        %ItemWithId{id: 2, name: "Bob"}
      ]

      stream = LiveStream.new(:users, make_ref(), users, [])

      assigns = %{
        users: stream,
        "v-component": "TestComponent",
        __changed__: nil
      }

      vue = render_vue_assigns(assigns)

      decoded = decode_patch(vue.streams_diff)

      # Should start with replace operation to reset
      reset_op = Enum.find(decoded, &(&1["path"] == "/users" && &1["op"] == "replace"))
      assert reset_op
      assert reset_op["value"] == []

      # Then should have upsert operations for items
      upsert_ops = Enum.filter(decoded, &(&1["op"] == "upsert"))
      assert length(upsert_ops) == 2
    end

    test "initial render with empty stream still resets" do
      stream = LiveStream.new(:users, make_ref(), [], [])

      assigns = %{
        users: stream,
        "v-component": "TestComponent",
        __changed__: nil
      }

      vue = render_vue_assigns(assigns)

      decoded = decode_patch(vue.streams_diff)

      # Should have at least the reset operation
      reset_op = Enum.find(decoded, &(&1["path"] == "/users" && &1["op"] == "replace"))
      assert reset_op
      assert reset_op["value"] == []
    end

    test "dead render (not connected) also triggers initial stream reset" do
      stream = LiveStream.new(:users, make_ref(), [%ItemWithId{id: 1, name: "Alice"}], [])

      # On dead render (no socket or socket not connected), streams should still be processed
      assigns = %{
        users: stream,
        "v-component": "TestComponent",
        __changed__: nil
      }

      vue = render_vue_assigns(assigns)

      decoded = decode_patch(vue.streams_diff)

      # Should reset because initial render (dead render is considered initial)
      reset_op = Enum.find(decoded, &(&1["path"] == "/users" && &1["op"] == "replace"))
      assert reset_op
      assert reset_op["value"] == []
    end
  end

  describe "calculate_props_diff/2 - edge cases with complex types" do
    test "changing from map to nil generates replace operation" do
      assigns = %{
        data: %{nested: %{value: 123}},
        "v-component": "TestComponent",
        __changed__: %{}
      }

      assigns = assign(assigns, :data, nil)
      vue = render_vue_assigns(assigns)

      assert_patches_equal(vue.props_diff, [
        %{"op" => "replace", "path" => "/data", "value" => nil}
      ])
    end

    test "changing from list to empty list generates remove operations" do
      assigns = %{
        items: [1, 2, 3],
        "v-component": "TestComponent",
        __changed__: %{}
      }

      assigns = assign(assigns, :items, [])
      vue = render_vue_assigns(assigns)

      decoded = decode_patch(vue.props_diff)

      # Should have remove operations for all items
      remove_ops = Enum.filter(decoded, &(&1["op"] == "remove"))
      assert length(remove_ops) == 3

      # Check paths exist
      paths = Enum.map(remove_ops, & &1["path"])
      assert "/items/0" in paths
      assert "/items/1" in paths
      assert "/items/2" in paths
    end

    test "changing from empty list to list with items generates add operations" do
      assigns = %{
        items: [],
        "v-component": "TestComponent",
        __changed__: %{}
      }

      assigns = assign(assigns, :items, [1, 2, 3])
      vue = render_vue_assigns(assigns)

      expected_patches = [
        %{"op" => "add", "path" => "/items/0", "value" => 1},
        %{"op" => "add", "path" => "/items/1", "value" => 2},
        %{"op" => "add", "path" => "/items/2", "value" => 3}
      ]

      assert_patches_equal(vue.props_diff, expected_patches)
    end

    test "deeply nested changes are detected correctly" do
      assigns = %{
        data: %{
          level1: %{
            level2: %{
              level3: %{
                value: "old"
              }
            }
          }
        },
        "v-component": "TestComponent",
        __changed__: %{}
      }

      assigns =
        assign(assigns, :data, %{
          level1: %{
            level2: %{
              level3: %{
                value: "new"
              }
            }
          }
        })

      vue = render_vue_assigns(assigns)

      assert_patches_equal(vue.props_diff, [
        %{"op" => "replace", "path" => "/data/level1/level2/level3/value", "value" => "new"}
      ])
    end
  end

  describe "prepare_diff/1 - both variants" do
    test "prepare_diff with value creates 3-element list" do
      assigns = %{
        name: "John",
        "v-component": "TestComponent",
        __changed__: %{}
      }

      assigns = assign(assigns, :name, "Jane")
      vue = render_vue_assigns(assigns)

      # Check that patches are compressed to 3-element lists
      assert Enum.all?(vue.props_diff, fn
               [_op, _path, _value] -> true
               ["test", "", _] -> true
               _ -> false
             end)
    end

    test "prepare_diff without value creates 2-element list" do
      items = [
        %ItemWithId{id: 1, name: "Alice"},
        %ItemWithId{id: 2, name: "Bob"}
      ]

      stream = LiveStream.new(:users, make_ref(), [], [])
      stream = LiveStream.delete_item(stream, %ItemWithId{id: 1, name: "Alice"})

      assigns = %{
        users: stream,
        "v-component": "TestComponent",
        __changed__: %{users: LiveStream.new(:users, make_ref(), items, [])}
      }

      vue = render_vue_assigns(assigns)

      # Remove operations should be 2-element lists (no value)
      remove_ops =
        Enum.filter(vue.streams_diff, fn
          ["remove", _path] -> true
          _ -> false
        end)

      assert length(remove_ops) > 0
    end
  end

  describe "key_changed/2 - both branches" do
    test "__changed__: nil returns true for all keys" do
      assigns = %{
        name: "John",
        age: 30,
        active: true,
        "v-component": "TestComponent",
        __changed__: nil
      }

      vue = render_vue_assigns(assigns)

      # On initial render, all props should be sent
      assert vue.props == %{"name" => "John", "age" => 30, "active" => true}

      # props_diff should be empty or only contain test operation
      decoded = decode_patch(vue.props_diff)
      assert decoded == []
    end

    test "__changed__ with changed map filters unchanged keys" do
      assigns = %{
        name: "John",
        age: 30,
        active: true,
        "v-component": "TestComponent",
        __changed__: %{}
      }

      # Only change name
      assigns = assign(assigns, :name, "Jane")
      vue = render_vue_assigns(assigns)

      # Props should contain full state (LiveComponent requirement)
      assert vue.props == %{"name" => "Jane", "age" => 30, "active" => true}

      # And should have corresponding diff
      decoded = decode_patch(vue.props_diff)
      assert length(decoded) == 1
      assert hd(decoded)["path"] == "/name"
    end
  end

  describe "LiveStream edge cases" do
    test "stream with update_only flag creates replace operation" do
      stream = LiveStream.new(:users, make_ref(), [], [])
      stream = LiveStream.insert_item(stream, %ItemWithId{id: 1, name: "Updated"}, -1, nil, true)

      assigns = %{
        users: stream,
        "v-component": "TestComponent",
        __changed__: %{users: LiveStream.new(:users, make_ref(), [], [])}
      }

      vue = render_vue_assigns(assigns)

      decoded = decode_patch(vue.streams_diff)

      # Should have replace operation instead of upsert
      replace_op = Enum.find(decoded, &(&1["op"] == "replace" && String.contains?(&1["path"], "$$")))
      assert replace_op
      assert replace_op["value"]["name"] == "Updated"
    end

    test "stream insert at position 0 uses 0 in path" do
      stream = LiveStream.new(:users, make_ref(), [], [])
      stream = LiveStream.insert_item(stream, %ItemWithId{id: 1, name: "First"}, 0, nil, false)

      assigns = %{
        users: stream,
        "v-component": "TestComponent",
        __changed__: %{users: LiveStream.new(:users, make_ref(), [], [])}
      }

      vue = render_vue_assigns(assigns)

      decoded = decode_patch(vue.streams_diff)

      # Should use 0 in path for position 0
      upsert_op = Enum.find(decoded, &(&1["op"] == "upsert"))
      assert upsert_op
      assert upsert_op["path"] == "/users/0"
    end

    test "stream insert at position -1 uses - in path" do
      stream = LiveStream.new(:users, make_ref(), [], [])
      stream = LiveStream.insert_item(stream, %ItemWithId{id: 1, name: "Last"}, -1, nil, false)

      assigns = %{
        users: stream,
        "v-component": "TestComponent",
        __changed__: %{users: LiveStream.new(:users, make_ref(), [], [])}
      }

      vue = render_vue_assigns(assigns)

      decoded = decode_patch(vue.streams_diff)

      # Should use - in path for position -1
      upsert_op = Enum.find(decoded, &(&1["op"] == "upsert"))
      assert upsert_op
      assert upsert_op["path"] == "/users/-"
    end

    test "stream with limit adds limit operation" do
      stream = LiveStream.new(:users, make_ref(), [], [])
      stream = LiveStream.insert_item(stream, %ItemWithId{id: 1, name: "User"}, -1, 5, false)

      assigns = %{
        users: stream,
        "v-component": "TestComponent",
        __changed__: %{users: LiveStream.new(:users, make_ref(), [], [])}
      }

      vue = render_vue_assigns(assigns)

      decoded = decode_patch(vue.streams_diff)

      # Should have limit operation
      limit_op = Enum.find(decoded, &(&1["op"] == "limit"))
      assert limit_op
      assert limit_op["path"] == "/users"
      assert limit_op["value"] == 5
    end

    test "stream without limit does not add limit operation" do
      stream = LiveStream.new(:users, make_ref(), [], [])
      stream = LiveStream.insert_item(stream, %ItemWithId{id: 1, name: "User"}, -1, nil, false)

      assigns = %{
        users: stream,
        "v-component": "TestComponent",
        __changed__: %{users: LiveStream.new(:users, make_ref(), [], [])}
      }

      vue = render_vue_assigns(assigns)

      decoded = decode_patch(vue.streams_diff)

      # Should not have limit operation
      limit_op = Enum.find(decoded, &(&1["op"] == "limit"))
      assert limit_op == nil
    end
  end

  describe "normalize_key edge cases" do
    test "special keys are not treated as props" do
      assigns = %{
        id: "custom-id",
        class: "custom-class",
        "v-ssr": false,
        "v-diff": false,
        "v-component": "TestComponent",
        regular_prop: "value",
        __changed__: nil
      }

      vue = render_vue_assigns(assigns)

      # Only regular_prop should be in props
      assert vue.props == %{"regular_prop" => "value"}

      # Special keys should be used for their specific purposes
      assert vue.id == "custom-id"
      assert vue.class == "custom-class"
      assert vue.ssr == false
      assert vue.use_diff == false
    end
  end
end

defmodule LiveVue.Encoder.LiveStreamTest do
  use ExUnit.Case

  alias LiveVue.Encoder
  alias Phoenix.LiveView.LiveStream

  defmodule TestUser do
    @moduledoc false

    defstruct [:id, :name, :age]

    defimpl Encoder do
      def encode(user, opts) do
        result = %{id: user.id, name: user.name}
        if opts[:encode_age], do: Map.put(result, :age, user.age), else: result
      end
    end
  end

  defmodule TestPost do
    @moduledoc false
    @derive Encoder
    defstruct [:id, :title, :content, :author_id]
  end

  describe "LiveStream encoding" do
    test "encodes empty stream as empty list" do
      stream = LiveStream.new(:users, make_ref(), [], [])

      assert Encoder.encode(stream) == []
    end

    test "encodes stream with single item" do
      user = %TestUser{id: 1, name: "John"}
      stream = LiveStream.new(:users, make_ref(), [user], [])

      expected = [%{id: 1, name: "John", __dom_id: "users-1"}]

      assert Encoder.encode(stream) == expected
    end

    test "encodes stream with multiple items in correct order" do
      users = [
        %TestUser{id: 1, name: "John"},
        %TestUser{id: 2, name: "Jane"},
        %TestUser{id: 3, name: "Bob"}
      ]

      stream = LiveStream.new(:users, make_ref(), users, [])

      expected = [
        %{id: 1, name: "John", __dom_id: "users-1"},
        %{id: 2, name: "Jane", __dom_id: "users-2"},
        %{id: 3, name: "Bob", __dom_id: "users-3"}
      ]

      assert Encoder.encode(stream) == expected
    end

    test "encodes stream with inserted items in correct order" do
      # Start with empty stream
      stream = LiveStream.new(:users, make_ref(), [], [])

      # Insert items (they get prepended, so in reverse order)
      user1 = %TestUser{id: 1, name: "John"}
      user2 = %TestUser{id: 2, name: "Jane"}
      user3 = %TestUser{id: 3, name: "Bob"}

      stream = LiveStream.insert_item(stream, user1, -1, nil, false)
      stream = LiveStream.insert_item(stream, user2, -1, nil, false)
      stream = LiveStream.insert_item(stream, user3, -1, nil, false)

      # Should return items in the correct order (not reversed)
      expected = [
        %{id: 1, name: "John", __dom_id: "users-1"},
        %{id: 2, name: "Jane", __dom_id: "users-2"},
        %{id: 3, name: "Bob", __dom_id: "users-3"}
      ]

      assert Encoder.encode(stream) == expected
    end

    test "handles duplicate items by using most recent insert" do
      user1_v1 = %TestUser{id: 1, name: "John"}
      user1_v2 = %TestUser{id: 1, name: "John Doe"}
      user2 = %TestUser{id: 2, name: "Jane"}

      stream = LiveStream.new(:users, make_ref(), [], [])

      # Insert same user twice (different versions)
      stream = LiveStream.insert_item(stream, user1_v1, -1, nil, false)
      stream = LiveStream.insert_item(stream, user2, -1, nil, false)
      stream = LiveStream.insert_item(stream, user1_v2, -1, nil, false)

      # Should only include the most recent version of user 1
      expected = [
        %{id: 2, name: "Jane", __dom_id: "users-2"},
        %{id: 1, name: "John Doe", __dom_id: "users-1"}
      ]

      assert Encoder.encode(stream) == expected
    end

    test "encodes stream with complex nested structs" do
      posts = [
        %TestPost{id: 1, title: "Hello World", content: "First post", author_id: 1},
        %TestPost{id: 2, title: "Elixir Rocks", content: "Second post", author_id: 2}
      ]

      stream = LiveStream.new(:posts, make_ref(), posts, [])

      expected = [
        %{id: 1, title: "Hello World", content: "First post", author_id: 1, __dom_id: "posts-1"},
        %{id: 2, title: "Elixir Rocks", content: "Second post", author_id: 2, __dom_id: "posts-2"}
      ]

      assert Encoder.encode(stream) == expected
    end

    test "encodes stream with primitive values" do
      # Stream with simple maps (not structs)
      items = [
        %{id: 1, value: "first"},
        %{id: 2, value: "second"}
      ]

      stream = LiveStream.new(:simple, make_ref(), items, [])

      expected = [
        %{id: 1, value: "first", __dom_id: "simple-1"},
        %{id: 2, value: "second", __dom_id: "simple-2"}
      ]

      assert Encoder.encode(stream) == expected
    end

    test "passes encoder options through to item encoding" do
      user = %TestUser{id: 1, name: "John", age: 30}
      stream = LiveStream.new(:users, make_ref(), [user], [])

      # The opts should be passed through to the item encoder
      # Since TestUser is properly encoded, the result should be the same
      expected = [%{id: 1, name: "John", age: 30, __dom_id: "users-1"}]

      assert Encoder.encode(stream, encode_age: true) == expected
    end
  end
end

defmodule LiveVuePatchTest do
  use ExUnit.Case

  alias LiveVue.Patch

  describe "values" do
    test "round-trips nil" do
      patches = [%{op: "replace", path: "/value", value: nil}]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips booleans" do
      patches = [
        %{op: "replace", path: "/enabled", value: true},
        %{op: "replace", path: "/disabled", value: false}
      ]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips integers" do
      patches = [%{op: "replace", path: "/count", value: 6}]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips floats" do
      patches = [%{op: "replace", path: "/price", value: 12.5}]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips strings" do
      patches = [%{op: "replace", path: "/title", value: "Published"}]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips lists" do
      patches = [%{op: "replace", path: "/tags", value: ["bug", "urgent"]}]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips maps" do
      patches = [%{op: "replace", path: "/user", value: %{"id" => 3, "name" => "Charlie"}}]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips caret-encoded JSON edge cases" do
      patches = [
        %{
          op: "replace",
          path: "/meta",
          value: %{"empty" => "", "caret" => "^", "tilde" => "~", "both" => "~^"}
        }
      ]

      assert serialize_deserialize(patches) == patches
    end
  end

  describe "paths" do
    test "round-trips the document root path" do
      patches = [%{op: "replace", path: "", value: %{"status" => "ready"}}]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips nested paths" do
      patches = [%{op: "replace", path: "/profile/name", value: "Ada"}]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips array index paths" do
      patches = [%{op: "replace", path: "/items/0/name", value: "Keyboard"}]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips append marker paths" do
      patches = [%{op: "add", path: "/items/-", value: "new"}]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips dots inside path segments" do
      patches = [%{op: "replace", path: "/settings/a.b.c", value: "value"}]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips JSON pointer escapes in path segments" do
      patches = [%{op: "replace", path: "/settings/a~1b~0c", value: "value"}]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips UTF-8 paths and values using JavaScript string lengths" do
      patches = [
        %{op: "replace", path: "/profile/na.me", value: "zażółć"},
        %{op: "replace", path: "/emoji", value: "🚀"}
      ]

      assert Patch.serialize(patches) == "r14:/profile/na.mes6:zażółćr6:/emojis2:🚀"
      assert serialize_deserialize(patches) == patches
    end
  end

  describe "operations" do
    test "round-trips an empty patch list" do
      patches = []

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips remove operations without a value" do
      patches = [%{op: "remove", path: "/items/0"}]

      assert serialize_deserialize(patches) == patches
    end

    test "omits nonce test operations when deserializing" do
      patches = [
        %{op: "test", path: "", value: 123},
        %{op: "replace", path: "/count", value: 6}
      ]

      assert serialize_deserialize(patches) == [%{op: "replace", path: "/count", value: 6}]
    end
  end

  describe "complex patches" do
    test "round-trips mixed scalar operations" do
      patches = [
        %{op: "replace", path: "/count", value: 6},
        %{op: "add", path: "/items/3", value: "d"},
        %{op: "remove", path: "/items/0"}
      ]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips nested object updates" do
      patches = [
        %{
          op: "replace",
          path: "/form/errors",
          value: %{
            "email" => ["must have the @ sign"],
            "age" => ["must be greater than 18"]
          }
        },
        %{op: "replace", path: "/form/touched", value: %{"email" => true, "age" => true}}
      ]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips stream upsert and limit operations" do
      patches = [
        %{
          op: "upsert",
          path: "/users/-",
          value: %{"id" => 4, "name" => "Margaret Hamilton", "role" => "guest"}
        },
        %{op: "limit", path: "/users", value: 10}
      ]

      assert serialize_deserialize(patches) == patches
    end

    test "round-trips multiple nested lists and objects" do
      patches = [
        %{
          op: "replace",
          path: "/cart/items/1",
          value: %{"id" => "sku-2", "name" => "Mouse", "qty" => 3, "price" => 49.5}
        },
        %{
          op: "replace",
          path: "/cart/totals",
          value: %{"subtotal" => 277.5, "tax" => 22.2, "total" => 299.7}
        },
        %{op: "replace", path: "/cart/coupon", value: nil}
      ]

      assert serialize_deserialize(patches) == patches
    end
  end

  defp serialize_deserialize(patches) do
    patches
    |> Patch.serialize()
    |> Patch.deserialize()
    |> Enum.map(&patch_from_wire/1)
  end

  defp patch_from_wire([op, path]), do: %{op: op, path: path}
  defp patch_from_wire([op, path, value]), do: %{op: op, path: path, value: value}
end

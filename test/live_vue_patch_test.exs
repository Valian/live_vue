defmodule LiveVuePatchTest do
  use ExUnit.Case

  alias LiveVue.Patch

  test "serializes and deserializes scalar operations" do
    patches = [
      %{op: "test", path: "", value: 123},
      %{op: "replace", path: "/count", value: 6},
      %{op: "add", path: "/items/3", value: "d"},
      %{op: "remove", path: "/items/0"}
    ]

    assert Patch.serialize(patches) == "n123r5:countn1:6a7:items.3s1:dd7:items.0"

    assert Patch.deserialize(Patch.serialize(patches)) == [
             ["replace", "/count", 6],
             ["add", "/items/3", "d"],
             ["remove", "/items/0"]
           ]
  end

  test "uses base64url JSON for complex values" do
    patches = [%{op: "add", path: "/rows", value: %{id: 3, name: "Charlie"}}]

    assert Patch.serialize(patches) == "a4:rowsJ34:eyJpZCI6MywibmFtZSI6IkNoYXJsaWUifQ"
    assert Patch.deserialize(Patch.serialize(patches)) == [["add", "/rows", %{"id" => 3, "name" => "Charlie"}]]
  end

  test "escapes dots in path segments while preserving JSON pointer escapes" do
    patches = [%{op: "replace", path: "/settings/a~1b~0c|d.e", value: "value"}]

    assert Patch.serialize(patches) == "r21:settings.a~1b~0c|d~2es5:value"
    assert Patch.deserialize(Patch.serialize(patches)) == [["replace", "/settings/a~1b~0c|d.e", "value"]]
  end

  test "uses UTF-8 byte lengths" do
    patches = [%{op: "replace", path: "/profile/na.me", value: "zażółć"}]

    assert Patch.serialize(patches) == "r14:profile.na~2mes10:zażółć"
    assert Patch.deserialize(Patch.serialize(patches)) == [["replace", "/profile/na.me", "zażółć"]]
  end
end

defmodule LiveViewDiffTest do
  use ExUnit.Case

  import Phoenix.Component

  alias LiveVue.Test
  alias Phoenix.LiveView.JS

  defmodule Company do
    @moduledoc false
    @derive LiveVue.Encoder
    defstruct [:name, :owner]
  end

  defmodule Team do
    @moduledoc false
    @derive LiveVue.Encoder
    defstruct [:name, :members, :lead]
  end

  # Test struct with sensitive fields that should be excluded
  defmodule SecureUser do
    @moduledoc false
    @derive {LiveVue.Encoder, except: [:password, :secret_key]}
    defstruct [:name, :age, :email, :password, :secret_key]
  end

  # Utility function to render Vue assigns and get parsed Vue properties
  defp render_vue_assigns(assigns) do
    rendered = LiveVue.vue(assigns)
    html = rendered |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Test.get_vue(html)
  end

  # Utility function to assert JSON patches are equal by sorting both by path
  defp assert_patches_equal(actual, expected) do
    actual_uncompressed =
      Enum.map(actual, fn patch ->
        %{"op" => Enum.at(patch, 0), "path" => Enum.at(patch, 1), "value" => Enum.at(patch, 2)}
      end)

    actual_sorted = Enum.sort_by(actual_uncompressed, & &1["path"])
    expected_sorted = Enum.sort_by(expected, & &1["path"])
    assert actual_sorted == expected_sorted
  end

  describe "props_diff functionality" do
    test "initial render has empty props_diff" do
      assigns = %{
        name: "John",
        age: 30,
        active: true,
        "v-component": "TestComponent",
        # This simulates the initial render
        __changed__: nil
      }

      vue = render_vue_assigns(assigns)

      assert vue.component == "TestComponent"
      assert vue.props == %{"name" => "John", "age" => 30, "active" => true}
      assert vue.use_diff == true
      assert_patches_equal(vue.props_diff, [])
    end

    test "single simple prop change creates replace operation" do
      assigns = %{
        name: "John",
        age: 30,
        "v-component": "TestComponent",
        __changed__: %{}
      }

      assigns = assign(assigns, :name, "Jane")
      vue = render_vue_assigns(assigns)

      assert_patches_equal(vue.props_diff, [
        %{"op" => "replace", "path" => "/name", "value" => "Jane"}
      ])
    end

    test "multiple simple prop changes create multiple replace operations" do
      assigns = %{
        name: "John",
        age: 30,
        active: true,
        "v-component": "TestComponent",
        __changed__: %{}
      }

      assigns =
        assigns
        |> assign(:name, "Alice")
        |> assign(:age, 25)

      vue = render_vue_assigns(assigns)

      expected_result = [
        %{"op" => "replace", "path" => "/age", "value" => 25},
        %{"op" => "replace", "path" => "/name", "value" => "Alice"}
      ]

      assert_patches_equal(vue.props_diff, expected_result)
    end

    test "complex prop changes use Jsonpatch.diff for minimal operations" do
      assigns = %{
        user: %{name: "John", age: 30},
        items: [1, 2, 3],
        config: %{debug: false},
        "v-component": "TestComponent",
        __changed__: %{}
      }

      assigns =
        assigns
        |> assign(:user, %{name: "Alice", age: 25})
        |> assign(:items, [1, 2, 3, 4])
        |> assign(:config, %{debug: true, timeout: 1000})

      vue = render_vue_assigns(assigns)

      expected_result = [
        %{"op" => "add", "path" => "/config/timeout", "value" => 1000},
        %{"op" => "replace", "path" => "/config/debug", "value" => true},
        %{"op" => "add", "path" => "/items/3", "value" => 4},
        %{"op" => "replace", "path" => "/user/age", "value" => 25},
        %{"op" => "replace", "path" => "/user/name", "value" => "Alice"}
      ]

      assert_patches_equal(vue.props_diff, expected_result)
    end

    test "unchanged props do not appear in diff" do
      assigns = %{
        name: "John",
        age: 30,
        active: true,
        "v-component": "TestComponent",
        __changed__: %{}
      }

      # Only change the name, leave age and active unchanged
      assigns = assign(assigns, :name, "Bob")
      vue = render_vue_assigns(assigns)
      # Only changed props should appear in diff
      assert_patches_equal(vue.props_diff, [%{"op" => "replace", "path" => "/name", "value" => "Bob"}])
    end

    test "no changes result in empty diff" do
      assigns = %{
        name: "John",
        age: 30,
        "v-component": "TestComponent",
        __changed__: %{}
      }

      vue = render_vue_assigns(assigns)
      assert_patches_equal(vue.props_diff, [])
    end

    test "changes to non-prop fields do not affect props_diff" do
      assigns = %{
        name: "John",
        age: 30,
        class: "old-class",
        id: "old-id",
        "v-on:click": JS.push("click"),
        "v-ssr": true,
        "v-component": "TestComponent",
        "v-socket": %Phoenix.LiveView.Socket{transport_pid: self()},
        __changed__: %{}
      }

      # Change only non-prop fields: handlers, class, id, v-ssr
      assigns =
        assigns
        |> assign(:class, "new-class")
        |> assign(:id, "new-id")
        |> assign(:"v-on:click", JS.push("test"))
        |> assign(:"v-ssr", false)

      vue = render_vue_assigns(assigns)

      # Props_diff should be empty since no actual props changed
      assert_patches_equal(vue.props_diff, [])

      # But props should still contain the unchanged prop values
      assert vue.props == %{}
      assert vue.handlers == %{"click" => %JS{ops: [["push", %{event: "test"}]]}}
    end

    test "list operations generate correct JSON Patch operations" do
      assigns = %{
        items: ["apple", "banana", "cherry"],
        "v-component": "TestComponent",
        __changed__: %{}
      }

      # Test removal
      assigns_remove = assign(assigns, :items, ["apple", "banana"])
      vue_remove = render_vue_assigns(assigns_remove)
      assert_patches_equal(vue_remove.props_diff, [%{"op" => "remove", "path" => "/items/2", "value" => nil}])

      # Test addition
      assigns_add = assign(assigns, :items, ["apple", "banana", "cherry", "date"])
      vue_add = render_vue_assigns(assigns_add)
      assert_patches_equal(vue_add.props_diff, [%{"op" => "add", "path" => "/items/3", "value" => "date"}])

      # Test replacement
      assigns_replace = assign(assigns, :items, ["apple", "orange", "cherry"])
      vue_replace = render_vue_assigns(assigns_replace)
      assert_patches_equal(vue_replace.props_diff, [%{"op" => "replace", "path" => "/items/1", "value" => "orange"}])
    end

    test "nested structure changes generate minimal diffs" do
      assigns = %{
        data: %{
          user: %{name: "Bob", age: 30},
          items: [1, 2],
          settings: %{theme: "dark"}
        },
        "v-component": "TestComponent",
        __changed__: %{}
      }

      # Complex nested changes
      assigns =
        assign(assigns, :data, %{
          # name changed, age same
          user: %{name: "Alice", age: 30},
          # item added
          items: [1, 2, 3],
          # theme changed, lang added
          settings: %{theme: "light", lang: "en"}
        })

      vue = render_vue_assigns(assigns)

      expected_result = [
        %{"op" => "add", "path" => "/data/items/2", "value" => 3},
        %{"op" => "add", "path" => "/data/settings/lang", "value" => "en"},
        %{"op" => "replace", "path" => "/data/settings/theme", "value" => "light"},
        %{"op" => "replace", "path" => "/data/user/name", "value" => "Alice"}
      ]

      assert_patches_equal(vue.props_diff, expected_result)
    end

    test "lists are diffed based on id field" do
      assigns = %{
        items: [
          %{id: 1, name: "Alice"},
          %{id: 2, name: "Bob"},
          %{
            id: 3,
            name: "Charlie",
            friends: [
              %{id: 4, name: "Diana"},
              %{id: 5, name: "Eve", favorite_colors: ["blue", "green"]}
            ]
          }
        ],
        "v-component": "TestComponent",
        __changed__: %{}
      }

      assigns =
        assign(assigns, :items, [
          # new user
          %{id: 8, name: "Fred"},
          %{id: 1, name: "Alice"},
          # updated user
          %{id: 2, name: "New Bob"},
          %{
            id: 3,
            name: "Charlie",
            friends: [
              %{id: 5, name: "New Eve", favorite_colors: ["blue", "red"]},
              # It's a new user because it has new id. So it should be removeal plus addition
              %{id: 6, name: "Diana"}
            ]
          }
        ])

      vue = render_vue_assigns(assigns)

      assert_patches_equal(vue.props_diff, [
        %{"op" => "add", "path" => "/items/0", "value" => %{"id" => 8, "name" => "Fred"}},
        %{"op" => "replace", "path" => "/items/2/name", "value" => "New Bob"},
        %{"op" => "remove", "path" => "/items/3/friends/0", "value" => nil},
        %{"op" => "replace", "path" => "/items/3/friends/0/favorite_colors/1", "value" => "red"},
        %{"op" => "replace", "path" => "/items/3/friends/0/name", "value" => "New Eve"},
        %{"op" => "add", "path" => "/items/3/friends/1", "value" => %{"id" => 6, "name" => "Diana"}}
      ])
    end

    test "it's possible to disable diffs" do
      assigns = %{
        user: %{name: "John", age: 30},
        "v-component": "TestComponent",
        "v-diff": false,
        __changed__: %{}
      }

      assigns = assign(assigns, :user, %{name: "Jane", age: 25})
      vue = render_vue_assigns(assigns)

      assert vue.use_diff == false
      assert vue.props == %{"user" => %{"name" => "Jane", "age" => 25}}
      assert_patches_equal(vue.props_diff, [])
    end

    defmodule User do
      @moduledoc false
      @derive LiveVue.Encoder
      defstruct [:name, :age]
    end

    defmodule UserWithPassword do
      @moduledoc false
      @derive LiveVue.Encoder
      defstruct [:name, :age, :password]
    end

    test "for structs uses protocol to convert to map" do
      assigns = %{
        user: %User{name: "John", age: 30},
        "v-component": "TestComponent",
        __changed__: %{}
      }

      assigns = assign(assigns, :user, %User{name: "Alice", age: 25})
      vue = render_vue_assigns(assigns)

      assert_patches_equal(vue.props_diff, [
        %{"op" => "replace", "path" => "/user/age", "value" => 25},
        %{"op" => "replace", "path" => "/user/name", "value" => "Alice"}
      ])
    end

    test "struct with sensitive fields is safely encoded" do
      assigns = %{
        user: %UserWithPassword{name: "John", age: 30, password: "secret123"},
        "v-component": "TestComponent",
        __changed__: %{}
      }

      assigns = assign(assigns, :user, %UserWithPassword{name: "Alice", age: 25, password: "newsecret"})
      vue = render_vue_assigns(assigns)

      # The password field should be included in the diff since it's a struct field
      # but it's been safely encoded through the protocol
      expected_result = [
        %{"op" => "replace", "path" => "/user/age", "value" => 25},
        %{"op" => "replace", "path" => "/user/name", "value" => "Alice"},
        %{"op" => "replace", "path" => "/user/password", "value" => "newsecret"}
      ]

      assert_patches_equal(vue.props_diff, expected_result)
    end

    test "initial render encodes struct props correctly" do
      assigns = %{
        user: %User{name: "John", age: 30},
        "v-component": "TestComponent",
        __changed__: nil
      }

      vue = render_vue_assigns(assigns)

      # Props should be encoded as plain maps
      assert vue.props == %{"user" => %{"name" => "John", "age" => 30}}
      assert_patches_equal(vue.props_diff, [])
    end

    test "structs in lists are handled correctly" do
      assigns = %{
        users: [
          %User{name: "John", age: 30},
          %User{name: "Jane", age: 25}
        ],
        "v-component": "TestComponent",
        __changed__: %{}
      }

      # Add a new user to the list
      assigns =
        assign(assigns, :users, [
          %User{name: "John", age: 30},
          %User{name: "Jane", age: 25},
          %User{name: "Bob", age: 35}
        ])

      vue = render_vue_assigns(assigns)

      assert_patches_equal(vue.props_diff, [
        %{"op" => "add", "path" => "/users/2", "value" => %{"name" => "Bob", "age" => 35}}
      ])
    end

    test "structs in maps are handled correctly" do
      assigns = %{
        people: %{
          admin: %User{name: "John", age: 30},
          user: %User{name: "Jane", age: 25}
        },
        "v-component": "TestComponent",
        __changed__: %{}
      }

      # Change the admin user
      assigns =
        assign(assigns, :people, %{
          admin: %User{name: "Alice", age: 28},
          user: %User{name: "Jane", age: 25}
        })

      vue = render_vue_assigns(assigns)

      expected_result = [
        %{"op" => "replace", "path" => "/people/admin/age", "value" => 28},
        %{"op" => "replace", "path" => "/people/admin/name", "value" => "Alice"}
      ]

      assert_patches_equal(vue.props_diff, expected_result)
    end

    test "nested structs are handled correctly" do
      assigns = %{
        company: %Company{
          name: "Tech Corp",
          owner: %User{name: "John", age: 30}
        },
        "v-component": "TestComponent",
        __changed__: %{}
      }

      # Change the owner
      assigns =
        assign(assigns, :company, %Company{
          name: "Tech Corp",
          owner: %User{name: "Alice", age: 28}
        })

      vue = render_vue_assigns(assigns)

      expected_result = [
        %{"op" => "replace", "path" => "/company/owner/age", "value" => 28},
        %{"op" => "replace", "path" => "/company/owner/name", "value" => "Alice"}
      ]

      assert_patches_equal(vue.props_diff, expected_result)
    end

    test "complex nested structure with multiple structs" do
      assigns = %{
        team: %Team{
          name: "Development",
          members: [
            %User{name: "Alice", age: 28},
            %User{name: "Bob", age: 32}
          ],
          lead: %User{name: "Charlie", age: 35}
        },
        "v-component": "TestComponent",
        __changed__: %{}
      }

      # Add a member and change the lead
      assigns =
        assign(assigns, :team, %Team{
          name: "Development",
          members: [
            %User{name: "Alice", age: 28},
            %User{name: "Bob", age: 32},
            %User{name: "Diana", age: 29}
          ],
          lead: %User{name: "Eve", age: 40}
        })

      vue = render_vue_assigns(assigns)

      expected_result = [
        %{"op" => "replace", "path" => "/team/lead/age", "value" => 40},
        %{"op" => "replace", "path" => "/team/lead/name", "value" => "Eve"},
        %{"op" => "add", "path" => "/team/members/2", "value" => %{"name" => "Diana", "age" => 29}}
      ]

      assert_patches_equal(vue.props_diff, expected_result)
    end

    test "deriving with except option excludes sensitive fields" do
      assigns = %{
        user: %SecureUser{
          name: "John",
          age: 30,
          email: "john@example.com",
          password: "secret123",
          secret_key: "abc123"
        },
        "v-component": "TestComponent",
        __changed__: nil
      }

      vue = render_vue_assigns(assigns)

      # Only non-sensitive fields should be encoded
      expected_props = %{
        "user" => %{
          "name" => "John",
          "age" => 30,
          "email" => "john@example.com"
        }
      }

      assert vue.props == expected_props
      assert_patches_equal(vue.props_diff, [])
    end

    test "deriving with except option handles changes properly" do
      assigns = %{
        user: %SecureUser{
          name: "John",
          age: 30,
          email: "john@example.com",
          password: "secret123",
          secret_key: "abc123"
        },
        "v-component": "TestComponent",
        __changed__: %{}
      }

      # Change both sensitive and non-sensitive fields
      assigns =
        assign(assigns, :user, %SecureUser{
          name: "Jane",
          age: 25,
          email: "jane@example.com",
          password: "newsecret",
          secret_key: "def456"
        })

      vue = render_vue_assigns(assigns)

      # Only changes to non-sensitive fields should appear in diff
      expected_result = [
        %{"op" => "replace", "path" => "/user/age", "value" => 25},
        %{"op" => "replace", "path" => "/user/email", "value" => "jane@example.com"},
        %{"op" => "replace", "path" => "/user/name", "value" => "Jane"}
      ]

      assert_patches_equal(vue.props_diff, expected_result)
    end

    test "assigning nil to complex value creates replace operation" do
      assigns = %{
        user: %{name: "John", age: 30, settings: %{theme: "dark"}},
        items: [1, 2, 3],
        config: %{debug: true, timeout: 1000},
        "v-component": "TestComponent",
        __changed__: %{}
      }

      # Assign nil to complex values
      assigns =
        assigns
        |> assign(:user, nil)
        |> assign(:items, 0)
        |> assign(:config, nil)

      vue = render_vue_assigns(assigns)

      expected_result = [
        %{"op" => "replace", "path" => "/config", "value" => nil},
        %{"op" => "replace", "path" => "/items", "value" => 0},
        %{"op" => "replace", "path" => "/user", "value" => nil}
      ]

      assert_patches_equal(vue.props_diff, expected_result)
    end

    test "updating date time works correctly" do
      assigns = %{
        date: ~U[2025-01-01 12:00:00Z],
        "v-component": "TestComponent",
        __changed__: %{}
      }

      assigns = assign(assigns, :date, ~U[2025-01-01 15:00:00Z])
      vue = render_vue_assigns(assigns)

      assert_patches_equal(vue.props_diff, [
        %{"op" => "replace", "path" => "/date", "value" => "2025-01-01T15:00:00Z"}
      ])
    end
  end
end

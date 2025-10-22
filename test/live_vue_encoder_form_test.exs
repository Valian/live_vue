defmodule LiveVue.EncoderFormTest do
  use ExUnit.Case

  import Ecto.Changeset
  import Phoenix.Component, only: [to_form: 2]

  alias Ecto.Association.NotLoaded
  alias LiveVue.Encoder
  alias Phoenix.HTML.FormData

  # Utility function to simplify test patterns
  defp encode_form(source, attrs) do
    module = source.__struct__
    changeset = module.changeset(source, attrs)
    form = FormData.to_form(changeset, as: module.__schema__(:source))
    Encoder.encode(form)
  end

  # Test schemas using Ecto.Schema for realistic form testing
  defmodule Simple do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    # Hide secret field from encoder
    @derive {Encoder, except: [:secret]}
    embedded_schema do
      field(:name, :string)
      field(:secret, :string)
      field(:age, :integer)
      field(:active, :boolean)
      field(:tags, {:array, :string})
      field(:score, :float)
    end

    def changeset(simple, attrs) do
      simple
      |> cast(attrs, [:name, :secret, :age, :active, :tags, :score])
      |> validate_required([:name])
      |> validate_number(:age, greater_than: 0)
      |> validate_number(:score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    end
  end

  defmodule Complex do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    alias LiveVue.EncoderFormTest.Simple

    # Hide private_data from encoder
    @derive {Encoder, except: [:private_data]}
    embedded_schema do
      field(:title, :string)
      # Self-referential embed for deep nesting
      embeds_one(:nested, __MODULE__)
      # List of simple structs
      embeds_many(:items, Simple, on_replace: :delete)
      # Hidden embedded field
      embeds_one(:private_data, Simple)
    end

    def changeset(complex, attrs) do
      complex
      |> cast(attrs, [:title])
      |> cast_embed(:nested)
      |> cast_embed(:items)
      |> cast_embed(:private_data)
      |> validate_required([:title])
      |> validate_length(:title, min: 1)
    end
  end

  # Association test schemas (simulating database-backed models)
  defmodule AssocProfile do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @derive {Encoder, except: [:secret_data]}
    schema "profiles" do
      field(:bio, :string)
      field(:secret_data, :string)
      field(:avatar_url, :string)
    end

    def changeset(profile, attrs) do
      cast(profile, attrs, [:bio, :secret_data, :avatar_url])
    end
  end

  defmodule AssocComment do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @derive {Encoder, except: [:internal_notes]}
    schema "comments" do
      field(:content, :string)
      field(:internal_notes, :string)
      field(:author, :string)
      field(:published, :boolean)
    end

    def changeset(comment, attrs) do
      cast(comment, attrs, [:content, :internal_notes, :author, :published])
    end
  end

  defmodule ComplexAssoc do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    alias LiveVue.EncoderFormTest.AssocComment
    alias LiveVue.EncoderFormTest.AssocProfile

    @derive {Encoder, except: [:private_data]}
    schema "complex_assocs" do
      field(:title, :string)
      field(:private_data, :string)
      # Association fields (simulating database relationships)
      has_one(:profile, AssocProfile, on_replace: :update)
      has_many(:comments, AssocComment, on_replace: :delete)
    end

    def changeset(complex_assoc, attrs) do
      complex_assoc
      |> cast(attrs, [:title, :private_data])
      |> cast_assoc(:profile)
      |> cast_assoc(:comments)
      |> validate_required([:title])
      |> validate_length(:title, min: 1)
    end
  end

  # Custom encoder implementation for demonstration
  defmodule CustomFormData do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    embedded_schema do
      field(:secret_field, :string)
      field(:public_field, :string)
      field(:metadata, :map)
    end

    def changeset(data, attrs) do
      cast(data, attrs, [:secret_field, :public_field, :metadata])
    end
  end

  defimpl LiveVue.Encoder, for: CustomFormData do
    def encode(struct, opts) do
      # Only expose public fields and transform metadata
      Encoder.encode(
        %{
          id: struct.id,
          public_field: struct.public_field,
          metadata: %{has_secret: !is_nil(struct.secret_field), field_count: map_size(Map.from_struct(struct)) - 1}
        },
        opts
      )

      # exclude __meta__
    end
  end

  describe "Phoenix.HTML.Form encoding" do
    test "encodes form with simple values" do
      simple = %Simple{}
      attrs = %{name: "John", secret: "hidden_value", age: 30, active: true, tags: ["elixir", "phoenix"], score: 95.5}
      encoded = encode_form(simple, attrs)

      assert encoded == %{
               name: "simple",
               values: %{
                 id: nil,
                 name: "John",
                 # secret excluded by encoder
                 age: 30,
                 active: true,
                 tags: ["elixir", "phoenix"],
                 score: 95.5
               },
               errors: %{},
               valid: true
             }
    end

    test "encodes form with validation errors" do
      simple = %Simple{}
      attrs = %{name: nil, age: -5, score: 150}
      encoded = encode_form(simple, attrs)

      assert encoded.name == "simple"
      assert encoded.valid == false

      assert encoded.values == %{
               id: nil,
               name: nil,
               # secret excluded by encoder
               age: -5,
               active: nil,
               tags: nil,
               score: 150
             }

      # Check error messages exist and have expected content
      assert encoded.errors == %{
               name: ["can't be blank"],
               age: ["must be greater than 0"],
               score: ["must be less than or equal to 100"]
             }
    end

    test "encodes form with mixed valid and invalid fields" do
      simple = %Simple{}
      attrs = %{name: "John", age: -5, active: true}
      encoded = encode_form(simple, attrs)

      assert encoded.name == "simple"
      assert encoded.valid == false

      assert encoded.values == %{
               id: nil,
               name: "John",
               # secret excluded by encoder
               age: -5,
               active: true,
               tags: nil,
               score: nil
             }

      # Only age should have errors
      assert Map.keys(encoded.errors) == [:age]
    end

    test "encodes form with nil values correctly" do
      simple = %Simple{}
      attrs = %{name: "John", secret: nil, age: nil, active: nil, tags: nil, score: nil}
      encoded = encode_form(simple, attrs)

      assert encoded.values == %{
               id: nil,
               name: "John",
               # secret excluded by encoder
               age: nil,
               active: nil,
               tags: nil,
               score: nil
             }
    end

    test "encodes form with nested embedded data" do
      complex = %Complex{}

      attrs = %{
        title: "Root Level",
        nested: %{
          title: "Level 1",
          nested: %{
            title: "Level 2"
          }
        },
        items: [
          %{name: "Item 1", age: 25, active: true},
          %{name: "Item 2", age: 30, active: false}
        ],
        private_data: %{
          name: "Secret",
          secret: "should be hidden"
        }
      }

      encoded = encode_form(complex, attrs)

      assert encoded.values == %{
               id: nil,
               title: "Root Level",
               nested: %{
                 id: nil,
                 title: "Level 1",
                 nested: %{
                   id: nil,
                   title: "Level 2",
                   nested: nil,
                   items: []
                   # private_data excluded by encoder
                 },
                 items: []
                 # private_data excluded by encoder
               },
               items: [
                 %{
                   id: nil,
                   name: "Item 1",
                   # secret excluded by encoder
                   age: 25,
                   active: true,
                   tags: nil,
                   score: nil
                 },
                 %{
                   id: nil,
                   name: "Item 2",
                   # secret excluded by encoder
                   age: 30,
                   active: false,
                   tags: nil,
                   score: nil
                 }
               ]
               # private_data excluded by encoder at root level
             }
    end
  end

  describe "complex nested form scenarios" do
    test "encodes form with deeply nested structures" do
      complex = %Complex{}

      attrs = %{
        title: "Level 0",
        nested: %{
          title: "Level 1",
          items: [
            %{name: "L1-Item1", age: 20, tags: ["tag1"]},
            %{name: "L1-Item2", age: 25, tags: ["tag2", "tag3"]}
          ],
          nested: %{
            title: "Level 2",
            items: [
              %{name: "L2-Item1", age: 30, active: true}
            ],
            nested: %{
              title: "Level 3"
            }
          }
        },
        items: [
          %{name: "L0-Item1", age: 35, score: 88.5},
          %{name: "L0-Item2", age: 40, score: 92.0}
        ],
        private_data: %{name: "Hidden", secret: "confidential"}
      }

      encoded = encode_form(complex, attrs)

      assert encoded.values.title == "Level 0"
      assert encoded.values.nested.title == "Level 1"
      assert encoded.values.nested.nested.title == "Level 2"
      assert encoded.values.nested.nested.nested.title == "Level 3"

      # Verify items at different levels
      assert length(encoded.values.items) == 2
      assert length(encoded.values.nested.items) == 2
      assert length(encoded.values.nested.nested.items) == 1

      # Verify private_data is excluded at all levels
      refute Map.has_key?(encoded.values, :private_data)
      refute Map.has_key?(encoded.values.nested, :private_data)
      refute Map.has_key?(encoded.values.nested.nested, :private_data)
    end

    test "encodes form with validation errors in nested data" do
      complex = %Complex{}

      attrs = %{
        # Invalid - should trigger validation error
        title: "",
        items: [
          # Invalid simple data
          %{name: nil, age: -100}
        ],
        nested: %{
          # Invalid nested title
          title: ""
        }
      }

      encoded = encode_form(complex, attrs)

      assert encoded.valid == false

      assert encoded.values == %{
               id: nil,
               # Should show submitted empty string
               title: "",
               items: [
                 %{
                   id: nil,
                   name: nil,
                   age: -100,
                   active: nil,
                   tags: nil,
                   score: nil
                 }
               ],
               nested: %{
                 id: nil,
                 title: "",
                 nested: nil,
                 items: []
               }
             }

      assert Map.has_key?(encoded.errors, :title)
    end

    test "encodes form with custom form data and encoder" do
      custom_data = %CustomFormData{}

      attrs = %{
        secret_field: "password123",
        public_field: "visible_data",
        metadata: %{internal: true}
      }

      encoded = encode_form(custom_data, attrs)

      # Form values now use the custom encoder, so secret_field is filtered out
      # and metadata is transformed according to the custom encoder
      assert encoded.values == %{
               id: nil,
               public_field: "visible_data",
               metadata: %{has_secret: true, field_count: 3}
               # secret_field excluded by custom encoder
             }
    end

    test "demonstrates encoder field control in forms" do
      # This test shows that Simple encoder excludes secret field and Complex excludes private_data
      simple = %Simple{}
      attrs = %{name: "John", secret: "confidential", age: 30}
      encoded = encode_form(simple, attrs)

      # Secret field is not included in form values due to @derive {Encoder, except: [:secret]}
      refute Map.has_key?(encoded.values, :secret)
      assert encoded.values.name == "John"
      assert encoded.values.age == 30

      # Test Complex struct with private_data exclusion
      complex = %Complex{}

      complex_attrs = %{
        title: "Test",
        private_data: %{name: "Secret Item", secret: "top-secret"}
      }

      complex_encoded = encode_form(complex, complex_attrs)

      # Private_data field not in values
      refute Map.has_key?(complex_encoded.values, :private_data)
      assert complex_encoded.values.title == "Test"
    end

    test "deletes items from existing Complex struct via form submission" do
      # Start with a Complex struct that ALREADY HAS items in it with IDs (like from database)
      complex = %Complex{
        title: "Existing Title",
        items: [
          %Simple{id: 1, name: "Item 1", age: 25, active: true},
          %Simple{id: 2, name: "Item 2", age: 30, active: false},
          %Simple{id: 3, name: "Item 3", age: 35, active: true}
        ]
      }

      # Now submit form params that only include 2 items (removing Item 2)
      # This simulates what would happen when user deletes an item in the UI
      # Note: we include IDs for the items we're keeping
      attrs = %{
        title: "Existing Title",
        items: [
          %{id: 1, name: "Item 1", age: 25, active: true},
          %{id: 3, name: "Item 3", age: 35, active: true}
        ]
      }

      encoded = encode_form(complex, attrs)

      # The encoded form should only show 2 items, not 3
      assert length(encoded.values.items) == 2

      # Verify the correct items remain
      item_names = Enum.map(encoded.values.items, & &1.name)
      assert "Item 1" in item_names
      assert "Item 3" in item_names
      refute "Item 2" in item_names
    end
  end

  describe "form error handling edge cases" do
    test "encodes form with deeply nested validation errors and affects parent validity" do
      complex = %Complex{}

      attrs = %{
        title: "Valid Parent",
        nested: %{
          # Invalid - empty title
          title: ""
        },
        items: [
          %{name: "Valid item"},
          # Invalid item
          %{name: nil, age: -5}
        ]
      }

      encoded = encode_form(complex, attrs)

      # Basic structure should be intact even with nested validation errors
      assert encoded.values == %{
               id: nil,
               title: "Valid Parent",
               nested: %{
                 id: nil,
                 title: "",
                 nested: nil,
                 items: []
               },
               items: [
                 %{
                   id: nil,
                   name: "Valid item",
                   age: nil,
                   active: nil,
                   tags: nil,
                   score: nil
                 },
                 %{
                   id: nil,
                   name: nil,
                   age: -5,
                   active: nil,
                   tags: nil,
                   score: nil
                 }
               ]
             }

      # The form itself is invalid due to nested errors
      assert encoded.valid == false

      # Nested validation errors are propagated to parent form
      assert encoded.errors == %{
               nested: %{
                 title: ["can't be blank"]
               },
               items: [
                 nil,
                 %{name: ["can't be blank"], age: ["must be greater than 0"]}
               ]
             }
    end
  end

  describe "form parameter handling with real changesets" do
    test "handles changeset with existing data and new params" do
      # Start with existing simple data
      simple = %Simple{name: "Original", secret: "original_secret", age: 20}

      # Apply new parameters
      attrs = %{name: "Updated", secret: "updated_secret", age: 25, active: true}
      encoded = encode_form(simple, attrs)

      # New parameters should override original data
      assert encoded.values == %{
               id: nil,
               name: "Updated",
               # secret excluded by encoder
               age: 25,
               active: true,
               tags: nil,
               score: nil
             }
    end

    test "handles string keys in changeset params with type casting" do
      simple = %Simple{name: "Alice"}
      # Use string keys (common in web forms) and test type casting
      attrs = %{"name" => "John", "secret" => "hidden", "age" => "30", "active" => "true", "score" => "87.5"}
      encoded = encode_form(simple, attrs)

      assert encoded.values == %{
               id: nil,
               name: "John",
               # secret excluded by encoder
               # Should be cast to integer
               age: 30,
               # Should be cast to boolean
               active: true,
               tags: nil,
               # Should be cast to float
               score: 87.5
             }
    end
  end

  describe "form values update behavior" do
    test "encodes form values from params even when changeset has validation errors" do
      # Start with existing data
      simple = %Simple{name: "Valid Name", age: 30}

      # Submit invalid parameters that should still be displayed in form
      # Both invalid but should be shown
      invalid_params = %{"name" => "", "age" => "-5"}
      encoded = encode_form(simple, invalid_params)

      # Form should show the invalid submitted values, not the original valid ones
      assert encoded.values == %{
               id: nil,
               # Should show submitted empty string, not nil
               name: "",
               # Should be -5 (the invalid submitted value), not 30
               age: -5,
               active: nil,
               tags: nil,
               score: nil
             }

      # Should have validation errors
      assert encoded.valid == false
      assert Map.has_key?(encoded.errors, :name)
      assert Map.has_key?(encoded.errors, :age)
    end

    test "encodes form values correctly with action set to validate" do
      # Start with existing data (simulate LiveView form state)
      simple = %Simple{name: "Original", age: 20, active: false}

      # Simulate form validation like in LiveView handle_event("validate", ...)
      new_params = %{"name" => "Updated Value", "age" => "30", "active" => "true"}

      _changeset =
        simple
        |> Simple.changeset(new_params)
        # This is what LiveView does
        |> Map.put(:action, :validate)

      encoded = encode_form(simple, new_params)

      # Test form validation with :validate action

      # Values should reflect the new params, not original data
      assert encoded.values == %{
               id: nil,
               # Should be new value
               name: "Updated Value",
               # Should be new value
               age: 30,
               # Should be new value
               active: true,
               tags: nil,
               score: nil
             }
    end

    test "encodes nested embedded form values correctly" do
      # Test with Complex schema to match example project structure
      complex = %Complex{title: "Original Title"}

      new_params = %{
        "title" => "Updated Title",
        "items" => [
          %{"name" => "New Item", "age" => "25", "active" => "true"}
        ]
      }

      _changeset =
        complex
        |> Complex.changeset(new_params)
        |> Map.put(:action, :validate)

      encoded = encode_form(complex, new_params)

      # Test complex nested form handling

      # Values should reflect the new params
      assert encoded.values.title == "Updated Title"
      assert length(encoded.values.items) == 1
      assert hd(encoded.values.items).name == "New Item"
      assert hd(encoded.values.items).age == 25
      assert hd(encoded.values.items).active == true
    end

    test "reproduces bug - embedded forms not showing submitted values when validation fails" do
      # Start with empty complex struct (like in LiveView mount)
      complex = %Complex{}

      # Simulate form submission with partial data that will cause validation errors
      # (missing required title, but has embedded data that should still be displayed)
      form_params = %{
        # Invalid - will cause validation error
        "title" => "",
        "items" => [
          %{"name" => "Item 1", "age" => "25", "active" => "true"},
          %{"name" => "Item 2", "age" => "30"}
        ],
        "nested" => %{
          "title" => "Nested Title",
          "items" => [
            %{"name" => "Nested Item", "age" => "20"}
          ]
        }
      }

      # Simulate LiveView validation logic
      _changeset =
        complex
        |> Complex.changeset(form_params)
        |> Map.put(:action, :validate)

      encoded = encode_form(complex, form_params)

      # Verify that embedded forms show submitted data correctly

      # Form should be invalid due to empty title
      assert encoded.valid == false

      # BUT the form values should still show all the submitted data
      # Title should show the submitted empty string
      assert encoded.values.title == ""

      # Items should show the submitted data (this is likely failing)
      assert length(encoded.values.items) == 2

      item1 = Enum.at(encoded.values.items, 0)
      assert item1.name == "Item 1"
      assert item1.age == 25
      assert item1.active == true

      item2 = Enum.at(encoded.values.items, 1)
      assert item2.name == "Item 2"
      assert item2.age == 30
      # Not provided, should be nil
      assert item2.active == nil

      # Nested data should show submitted values
      assert encoded.values.nested
      assert encoded.values.nested.title == "Nested Title"
      assert length(encoded.values.nested.items) == 1
      nested_item = hd(encoded.values.nested.items)
      assert nested_item.name == "Nested Item"
      assert nested_item.age == 20
    end

    test "reproduces specific bug - required embedded field with partial data becomes nil" do
      # Test the exact issue: when a required embedded field has partial data that fails validation,
      # the entire embedded field becomes nil instead of showing the partial submitted data

      complex = %Complex{}

      # Submit data where the embedded field will fail validation due to missing required fields
      form_params = %{
        "title" => "Valid Title",
        # Nested has partial data but missing required title - this should cause validation error
        # but we should still see the submitted items, not nil
        "nested" => %{
          # Empty title - required field
          "title" => "",
          "items" => [
            %{"name" => "Submitted Item", "age" => "25"}
          ]
        }
      }

      _changeset =
        complex
        |> Complex.changeset(form_params)
        |> Map.put(:action, :validate)

      encoded = encode_form(complex, form_params)

      # Test embedded forms with validation errors

      # Form should be invalid due to nested validation error
      assert encoded.valid == false

      # The key bug: nested should NOT be nil - it should show the submitted data
      # even if validation failed
      assert encoded.values.nested
      # Empty string becomes nil after casting
      assert encoded.values.nested.title == ""
      assert length(encoded.values.nested.items) == 1
      assert hd(encoded.values.nested.items).name == "Submitted Item"
      assert hd(encoded.values.nested.items).age == 25
    end

    test "form shows all submitted params including invalid types excluded from changeset.changes" do
      # This test verifies that invalid parameters that fail casting are still displayed in forms
      # rather than showing as nil, ensuring users see what they actually submitted

      simple = %Simple{}

      # Test both with and without :validate action to ensure consistent behavior
      form_params = %{
        "name" => "Valid Name",
        # Invalid types that should show as submitted strings, not nil
        "age" => "not_a_number",
        "active" => "invalid_bool",
        "score" => "invalid_float"
      }

      # Test with :validate action (like LiveView validation)
      _changeset_with_action =
        simple
        |> Simple.changeset(form_params)
        |> Map.put(:action, :validate)

      encoded = encode_form(simple, form_params)

      # Form should be invalid due to cast failures
      assert encoded.valid == false

      # Valid field should show cast value
      assert encoded.values.name == "Valid Name"

      # Key fix: invalid fields should show submitted string values, not nil
      # This ensures users see what they typed even if casting failed
      assert encoded.values.age == "not_a_number", "Age should show submitted value, not nil"
      assert encoded.values.active == "invalid_bool", "Active should show submitted value, not nil"
      assert encoded.values.score == "invalid_float", "Score should show submitted value, not nil"

      # Test also works without :validate action
      encoded_without_action = encode_form(simple, form_params)
      assert encoded_without_action.values.age == "not_a_number"
      assert encoded_without_action.values.active == "invalid_bool"
      assert encoded_without_action.values.score == "invalid_float"
    end
  end

  describe "forms backed by simple maps" do
    test "encodes form backed by simple map data" do
      form_data = %{
        "name" => "John Doe",
        "email" => "john@example.com",
        "role" => "developer",
        "bio" => "Software engineer with 5 years experience",
        "notifications" => true
      }

      form = to_form(form_data, as: :user)
      encoded = Encoder.encode(form)

      assert encoded == %{
               name: "user",
               values: %{
                 "name" => "John Doe",
                 "email" => "john@example.com",
                 "role" => "developer",
                 "bio" => "Software engineer with 5 years experience",
                 "notifications" => true
               },
               errors: %{},
               valid: true
             }
    end

    test "encodes form with empty map data" do
      form_data = %{
        "name" => "",
        "email" => "",
        "role" => "",
        "bio" => "",
        "notifications" => false
      }

      form = to_form(form_data, as: :profile)
      encoded = Encoder.encode(form)

      assert encoded == %{
               name: "profile",
               values: %{
                 "name" => "",
                 "email" => "",
                 "role" => "",
                 "bio" => "",
                 "notifications" => false
               },
               errors: %{},
               valid: true
             }
    end

    test "encodes form with mixed data types" do
      form_data = %{
        "name" => "Alice Smith",
        "age" => 28,
        "active" => true,
        "score" => 95.5,
        "tags" => ["elixir", "phoenix", "liveview"],
        "metadata" => %{
          "created_at" => ~D[2023-01-15],
          "preferences" => %{"theme" => "dark", "notifications" => false}
        }
      }

      form = to_form(form_data, as: :user_profile)
      encoded = Encoder.encode(form)

      assert encoded.name == "user_profile"
      assert encoded.valid == true
      assert encoded.errors == %{}

      assert encoded.values == %{
               "name" => "Alice Smith",
               "age" => 28,
               "active" => true,
               "score" => 95.5,
               "tags" => ["elixir", "phoenix", "liveview"],
               "metadata" => %{
                 # Date encoded to string
                 "created_at" => "2023-01-15",
                 "preferences" => %{"theme" => "dark", "notifications" => false}
               }
             }
    end

    test "encodes form with params override" do
      form_data = %{
        "name" => "Original Name",
        "email" => "original@example.com"
      }

      # Simulate form submission with new params
      form = to_form(form_data, as: :user)
      form_with_params = %{form | params: %{"name" => "Updated Name", "role" => "admin"}}

      encoded = Encoder.encode(form_with_params)

      # Params should override original data and add new fields
      # Note: for map-backed forms, only params are included (no merge with original data happens)
      assert encoded.values == %{
               # overridden by params
               "name" => "Updated Name",
               # new from params
               "role" => "admin"
               # "email" not included since it wasn't in params for map forms
             }
    end

    test "encodes form with hidden fields" do
      form_data = %{
        "name" => "John",
        "email" => "john@example.com"
      }

      form = to_form(form_data, as: :user)
      # Add hidden fields (like CSRF token)
      form_with_hidden = %{form | hidden: [csrf_token: "abc123", user_id: 42]}

      encoded = Encoder.encode(form_with_hidden)

      assert encoded.values == %{
               # from data
               "name" => "John",
               # from data
               "email" => "john@example.com",
               # from hidden
               csrf_token: "abc123",
               # from hidden
               user_id: 42
             }
    end

    test "encodes nested map structure" do
      form_data = %{
        "user" => %{
          "name" => "Jane",
          "profile" => %{
            "bio" => "Developer",
            "social" => %{
              "twitter" => "@jane",
              "github" => "jane-dev"
            }
          }
        },
        "settings" => %{
          "theme" => "dark",
          "notifications" => true
        }
      }

      form = to_form(form_data, as: :complex_form)
      encoded = Encoder.encode(form)

      assert encoded.values == %{
               "user" => %{
                 "name" => "Jane",
                 "profile" => %{
                   "bio" => "Developer",
                   "social" => %{
                     "twitter" => "@jane",
                     "github" => "jane-dev"
                   }
                 }
               },
               "settings" => %{
                 "theme" => "dark",
                 "notifications" => true
               }
             }
    end

    test "encodes form with structs in map data" do
      form_data = %{
        "name" => "Test User",
        "created_at" => ~D[2023-12-25],
        "updated_at" => ~N[2023-12-25 10:30:00],
        "simple_item" => %Simple{
          name: "Item Name",
          secret: "secret123",
          age: 25,
          active: true
        },
        "custom_item" => %CustomFormData{
          secret_field: "secret456",
          public_field: "visible_data",
          metadata: %{internal: true}
        }
      }

      form = to_form(form_data, as: :mixed_form)
      encoded = Encoder.encode(form)

      assert encoded.values == %{
               "name" => "Test User",
               # Date encoded to string
               "created_at" => "2023-12-25",
               # NaiveDateTime encoded to string
               "updated_at" => "2023-12-25T10:30:00",
               "simple_item" => %{
                 id: nil,
                 name: "Item Name",
                 # secret excluded by encoder
                 age: 25,
                 active: true,
                 tags: nil,
                 score: nil
               },
               "custom_item" => %{
                 id: nil,
                 public_field: "visible_data",
                 metadata: %{has_secret: true, field_count: 3}
                 # secret_field excluded by custom encoder
               }
             }
    end
  end

  # Test module for excluded association testing
  defmodule TestWithExcludedAssoc do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    alias LiveVue.EncoderFormTest.AssocProfile

    # Exclude the association field
    @derive {Encoder, except: [:profile]}
    schema "test_with_excluded_assoc" do
      field(:title, :string)
      has_one(:profile, AssocProfile)
    end

    def changeset(struct, attrs) do
      cast(struct, attrs, [:title])
    end
  end

  # Test module for multiple excluded fields
  defmodule TestMultipleExcluded do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    alias LiveVue.EncoderFormTest.AssocComment
    alias LiveVue.EncoderFormTest.AssocProfile

    @derive {Encoder, except: [:profile, :secret, :comments]}
    schema "test_multiple_excluded" do
      field(:title, :string)
      field(:secret, :string)
      has_one(:profile, AssocProfile)
      has_many(:comments, AssocComment)
    end

    def changeset(struct, attrs) do
      cast(struct, attrs, [:title, :secret])
    end
  end

  describe "association handling" do
    test "encodes form with loaded has_one association" do
      # Simulate a loaded association from database
      profile = %AssocProfile{
        id: 1,
        bio: "Software developer",
        secret_data: "confidential info",
        avatar_url: "https://example.com/avatar.jpg"
      }

      complex_assoc = %ComplexAssoc{
        id: 1,
        title: "Main Article",
        private_data: "internal notes",
        profile: profile,
        comments: []
      }

      attrs = %{title: "Updated Article"}
      encoded = encode_form(complex_assoc, attrs)

      assert encoded.values == %{
               id: 1,
               title: "Updated Article",
               # private_data excluded by encoder
               profile: %{
                 id: 1,
                 bio: "Software developer",
                 # secret_data excluded by encoder
                 avatar_url: "https://example.com/avatar.jpg"
               },
               comments: []
             }
    end

    test "encodes form with nil has_one association (not loaded)" do
      # Simulate association not loaded from database
      complex_assoc = %ComplexAssoc{
        id: 1,
        title: "Main Article",
        private_data: "internal notes",
        profile: nil,
        comments: []
      }

      attrs = %{title: "Updated Article"}
      encoded = encode_form(complex_assoc, attrs)

      assert encoded.values == %{
               id: 1,
               title: "Updated Article",
               # private_data excluded by encoder
               profile: nil,
               comments: []
             }
    end

    test "encodes form with has_one association using Ecto.Association.NotLoaded" do
      # When creating a struct without specifying associations, they default to NotLoaded
      complex_assoc = %ComplexAssoc{
        id: 1,
        title: "Main Article",
        private_data: "internal notes",
        comments: []
        # profile field omitted - defaults to NotLoaded
      }

      attrs = %{title: "Updated Article"}

      # Should raise an error that the association is not loaded
      exception = assert_raise Protocol.UndefinedError, fn -> encode_form(complex_assoc, attrs) end
      message = Exception.format_banner(:error, exception)
      assert String.contains?(message, "association :profile is not loaded")
      assert String.contains?(message, "nillify_not_loaded: true")
    end

    test "encodes form with loaded has_many associations" do
      # Simulate loaded comments from database
      comments = [
        %AssocComment{
          id: 1,
          content: "Great article!",
          internal_notes: "approved by moderator",
          author: "user1",
          published: true
        },
        %AssocComment{
          id: 2,
          content: "Very helpful",
          internal_notes: "flagged for review",
          author: "user2",
          published: false
        }
      ]

      complex_assoc = %ComplexAssoc{
        id: 1,
        title: "Main Article",
        private_data: "internal notes",
        comments: comments,
        profile: nil
      }

      attrs = %{title: "Updated Article"}
      encoded = encode_form(complex_assoc, attrs)

      assert encoded.values == %{
               id: 1,
               title: "Updated Article",
               # private_data excluded by encoder
               profile: nil,
               comments: [
                 %{
                   id: 1,
                   content: "Great article!",
                   # internal_notes excluded by encoder
                   author: "user1",
                   published: true
                 },
                 %{
                   id: 2,
                   content: "Very helpful",
                   # internal_notes excluded by encoder
                   author: "user2",
                   published: false
                 }
               ]
             }
    end

    test "encodes form with empty has_many associations" do
      # Simulate empty loaded association (no comments)
      complex_assoc = %ComplexAssoc{
        id: 1,
        title: "Main Article",
        private_data: "internal notes",
        profile: nil,
        comments: []
      }

      attrs = %{title: "Updated Article"}
      encoded = encode_form(complex_assoc, attrs)

      assert encoded.values == %{
               id: 1,
               title: "Updated Article",
               # private_data excluded by encoder
               profile: nil,
               comments: []
             }
    end

    test "encodes form with has_many association using Ecto.Association.NotLoaded" do
      # When creating a struct without specifying associations, they default to NotLoaded
      complex_assoc = %ComplexAssoc{
        id: 1,
        title: "Main Article",
        private_data: "internal notes",
        profile: nil
        # comments field omitted - defaults to NotLoaded
      }

      attrs = %{title: "Updated Article"}

      # Should raise an error that the association is not loaded
      exception = assert_raise Protocol.UndefinedError, fn -> encode_form(complex_assoc, attrs) end
      message = Exception.format_banner(:error, exception)
      assert String.contains?(message, "association :comments is not loaded")
      assert String.contains?(message, "nillify_not_loaded: true")
    end

    test "encodes form with cast_assoc changes for has_one association" do
      # Start with existing association
      profile = %AssocProfile{id: 1, bio: "Old bio", avatar_url: "old.jpg"}

      complex_assoc = %ComplexAssoc{
        id: 1,
        title: "Article",
        profile: profile,
        comments: []
      }

      # Update association through cast_assoc (include ID for update)
      attrs = %{
        title: "Updated Article",
        profile: %{id: 1, bio: "New bio", avatar_url: "new.jpg"}
      }

      encoded = encode_form(complex_assoc, attrs)

      assert encoded.values == %{
               id: 1,
               title: "Updated Article",
               # private_data excluded by encoder
               profile: %{
                 id: 1,
                 bio: "New bio",
                 # secret_data excluded by encoder
                 avatar_url: "new.jpg"
               },
               comments: []
             }
    end

    test "encodes form with cast_assoc changes for has_many associations" do
      # Start with existing comments
      comments = [
        %AssocComment{id: 1, content: "Old comment", author: "user1", published: true}
      ]

      complex_assoc = %ComplexAssoc{
        id: 1,
        title: "Article",
        comments: comments,
        profile: nil
      }

      # Update and add comments through cast_assoc
      attrs = %{
        title: "Updated Article",
        comments: [
          %{id: 1, content: "Updated comment", author: "user1", published: false},
          %{content: "New comment", author: "user2", published: true}
        ]
      }

      encoded = encode_form(complex_assoc, attrs)

      assert encoded.values == %{
               id: 1,
               title: "Updated Article",
               # private_data excluded by encoder
               profile: nil,
               comments: [
                 %{
                   id: 1,
                   content: "Updated comment",
                   # internal_notes excluded by encoder
                   author: "user1",
                   published: false
                 },
                 %{
                   id: nil,
                   content: "New comment",
                   # internal_notes excluded by encoder
                   author: "user2",
                   published: true
                 }
               ]
             }
    end

    test "encodes form with validation errors in has_one association" do
      complex_assoc = %ComplexAssoc{id: 1, title: "Article", comments: [], profile: nil}

      # Submit invalid association data
      attrs = %{
        title: "Valid Title",
        # Invalid - assuming bio is required in real scenario
        profile: %{bio: "", avatar_url: nil}
      }

      encoded = encode_form(complex_assoc, attrs)

      # Should show submitted association data even if validation fails
      assert encoded.values == %{
               id: 1,
               title: "Valid Title",
               # private_data excluded by encoder
               profile: %{
                 id: nil,
                 bio: "",
                 # secret_data excluded by encoder
                 avatar_url: nil
               },
               comments: []
             }
    end

    test "encodes form with validation errors in has_many associations" do
      complex_assoc = %ComplexAssoc{id: 1, title: "Article", profile: nil, comments: []}

      # Submit mix of valid and invalid comment data
      attrs = %{
        title: "Valid Title",
        comments: [
          %{content: "Valid comment", author: "user1", published: true},
          # Invalid comment
          %{content: "", author: nil, published: false}
        ]
      }

      encoded = encode_form(complex_assoc, attrs)

      # Should show all submitted data, both valid and invalid
      assert encoded.values == %{
               id: 1,
               title: "Valid Title",
               # private_data excluded by encoder
               profile: nil,
               comments: [
                 %{
                   id: nil,
                   content: "Valid comment",
                   # internal_notes excluded by encoder
                   author: "user1",
                   published: true
                 },
                 %{
                   id: nil,
                   content: "",
                   # internal_notes excluded by encoder
                   author: nil,
                   published: false
                 }
               ]
             }
    end

    test "handles mixed association states - loaded profile with new comments" do
      # Mix of loaded association with new association data
      existing_profile = %AssocProfile{id: 1, bio: "Existing bio", avatar_url: "old.jpg"}

      complex_assoc = %ComplexAssoc{
        id: 1,
        title: "Article",
        profile: existing_profile,
        # Start with empty comments
        comments: []
      }

      # Update existing profile and add new comments (include ID for update)
      attrs = %{
        profile: %{id: 1, bio: "Updated bio", avatar_url: "new.jpg"},
        comments: [
          %{content: "First comment", author: "user1", published: true},
          %{content: "Second comment", author: "user2", published: false}
        ]
      }

      encoded = encode_form(complex_assoc, attrs)

      assert encoded.values == %{
               id: 1,
               title: "Article",
               # private_data excluded by encoder
               profile: %{
                 id: 1,
                 bio: "Updated bio",
                 # secret_data excluded by encoder
                 avatar_url: "new.jpg"
               },
               comments: [
                 %{
                   id: nil,
                   content: "First comment",
                   # internal_notes excluded by encoder
                   author: "user1",
                   published: true
                 },
                 %{
                   id: nil,
                   content: "Second comment",
                   # internal_notes excluded by encoder
                   author: "user2",
                   published: false
                 }
               ]
             }
    end

    test "handles association corner cases properly" do
      # Test basic association handling with both nil and empty associations
      complex_assoc = %ComplexAssoc{
        id: 1,
        title: "Article with Basic Associations",
        profile: nil,
        comments: []
      }

      attrs = %{title: "Updated Article"}
      encoded = encode_form(complex_assoc, attrs)

      # Verify basic association encoding works correctly
      assert encoded.values == %{
               id: 1,
               title: "Updated Article",
               # private_data excluded by encoder
               profile: nil,
               comments: []
             }
    end

    test "handles NotLoaded associations when nillify_not_loaded option is used" do
      # Create a struct with NotLoaded association that is excluded by encoder
      test_struct = %TestWithExcludedAssoc{
        id: 1,
        title: "Test with NotLoaded Association",
        # This field is excluded by encoder but would normally cause an error
        profile: %NotLoaded{
          __field__: :profile,
          __owner__: TestWithExcludedAssoc,
          __cardinality__: :one
        }
      }

      attrs = %{title: "Updated Title"}

      # This should work without error when nillify_not_loaded is true
      changeset = TestWithExcludedAssoc.changeset(test_struct, attrs)
      form = FormData.to_form(changeset, as: :test_with_excluded_assoc)

      # Test with nillify_not_loaded option - should not try to access excluded profile field
      encoded = Encoder.encode(form, nillify_not_loaded: true)

      assert encoded.values == %{
               id: 1,
               title: "Updated Title"
               # profile excluded by encoder (and never accessed due to nillify_not_loaded)
             }
    end

    test "nillify_not_loaded works with multiple excluded fields" do
      test_struct = %TestMultipleExcluded{
        id: 1,
        title: "Test",
        secret: "secret data",
        profile: %NotLoaded{
          __field__: :profile,
          __owner__: TestMultipleExcluded,
          __cardinality__: :one
        },
        comments: %NotLoaded{
          __field__: :comments,
          __owner__: TestMultipleExcluded,
          __cardinality__: :many
        }
      }

      attrs = %{title: "Updated Title", secret: "new secret"}

      changeset = TestMultipleExcluded.changeset(test_struct, attrs)
      form = FormData.to_form(changeset, as: :test_multiple_excluded)

      # Should work without accessing NotLoaded associations
      encoded = Encoder.encode(form, nillify_not_loaded: true)

      # Should only include non-excluded fields
      assert encoded.values == %{
               id: 1,
               title: "Updated Title"
               # secret, profile, comments all excluded by encoder
             }
    end
  end

  describe "error translation" do
    test "translate_error interpolates multiple placeholders in form errors" do
      # Create a changeset with validation errors that have interpolation placeholders
      simple = %Simple{}

      changeset =
        simple
        |> Simple.changeset(%{name: "x", age: 150})
        |> add_error(:name, "field %{fields} must have at least %{min} characters", min: 2, fields: ["name"])
        |> add_error(:score, "must be between %{min} and %{max}", min: 0.0, max: 100.0)
        |> Map.put(:valid?, false)

      form = FormData.to_form(changeset, as: Simple.__schema__(:source))
      encoded = Encoder.encode(form)

      # Verify interpolation worked correctly in the encoded form errors
      assert encoded.errors.name == ["field name must have at least 2 characters"]
      assert encoded.errors.score == ["must be between 0.0 and 100.0"]
    end
  end

  describe "embed_many with item additions and removals" do
    test "error array length matches values array when items are removed" do
      # When items are removed from embed_many, the error array should have the same
      # length as the values array (filtering out deleted items with params == nil)
      complex = %Complex{
        title: "Parent",
        items: [
          %Simple{id: 1, name: "Item 1", age: 25},
          %Simple{id: 2, name: "Item 2", age: 30},
          %Simple{id: 3, name: "Item 3", age: 35}
        ]
      }

      # Remove item 2, add validation errors to items 1 and new item
      attrs = %{
        title: "Parent",
        items: [
          %{id: 1, name: "Item 1", age: -5},
          %{id: 3, name: "Item 3", age: 35},
          %{name: nil, age: 40}
        ]
      }

      encoded = encode_form(complex, attrs)

      # Values and errors arrays should have matching lengths
      assert length(encoded.values.items) == 3
      assert length(encoded.errors.items) == 3

      # Errors should be in same order as values
      assert encoded.errors.items == [
               %{age: ["must be greater than 0"]},
               nil,
               %{name: ["can't be blank"]}
             ]
    end

    test "deeply nested embed_many with additions and removals" do
      complex = %Complex{
        title: "Root",
        nested: %Complex{
          title: "Level 1",
          items: [
            %Simple{id: 1, name: "L1-Item1", age: 20},
            %Simple{id: 2, name: "L1-Item2", age: 25}
          ]
        }
      }

      # Add new item between existing ones
      attrs = %{
        title: "Root",
        nested: %{
          title: "Level 1",
          items: [
            %{id: 1, name: nil, age: -5},
            %{name: "New Item", age: 30},
            %{id: 2, name: "L1-Item2", age: 25}
          ]
        }
      }

      encoded = encode_form(complex, attrs)

      # Nested errors should also have matching length
      nested_errors = encoded.errors.nested.items
      assert length(nested_errors) == 3
      assert nested_errors == [
               %{name: ["can't be blank"], age: ["must be greater than 0"]},
               nil,
               nil
             ]
    end
  end

  describe "multiple checkbox field handling" do
    # Schema for testing multiple checkboxes
    defmodule MultipleChoiceForm do
      @moduledoc false
      use Ecto.Schema

      import Ecto.Changeset

      @derive {Encoder, except: [:internal_data]}
      embedded_schema do
        field(:title, :string)
        field(:preferences, {:array, :string})
        field(:tags, {:array, :string})
        field(:internal_data, :string)
      end

      def changeset(form, attrs) do
        form
        |> cast(attrs, [:title, :preferences, :tags, :internal_data])
        |> validate_required([:title])
      end
    end

    test "encodes form with multiple checkbox fields (array values)" do
      form_data = %MultipleChoiceForm{}

      # Simulate form submission with multiple checkbox selections
      attrs = %{
        "title" => "User Preferences",
        "preferences" => ["email_notifications", "sms_alerts", "push_notifications"],
        "tags" => ["developer", "elixir", "phoenix"]
      }

      encoded = encode_form(form_data, attrs)

      assert encoded.values == %{
               id: nil,
               title: "User Preferences",
               preferences: ["email_notifications", "sms_alerts", "push_notifications"],
               tags: ["developer", "elixir", "phoenix"]
               # internal_data excluded by encoder
             }
    end

    test "encodes form with partial checkbox selections" do
      form_data = %MultipleChoiceForm{}

      attrs = %{
        "title" => "Partial Selection",
        # Only one selected
        "preferences" => ["email_notifications"],
        # None selected
        "tags" => []
      }

      encoded = encode_form(form_data, attrs)

      assert encoded.values == %{
               id: nil,
               title: "Partial Selection",
               preferences: ["email_notifications"],
               tags: []
               # internal_data excluded by encoder
             }
    end

    test "encodes form with no checkbox selections" do
      form_data = %MultipleChoiceForm{}

      attrs = %{
        "title" => "No Selections",
        "preferences" => [],
        "tags" => []
      }

      encoded = encode_form(form_data, attrs)

      assert encoded.values == %{
               id: nil,
               title: "No Selections",
               preferences: [],
               tags: []
               # internal_data excluded by encoder
             }
    end

    test "handles form with Phoenix multiple field pattern" do
      # This tests the pattern from core_components.ex:295
      # where multiple=true causes field.name <> "[]"

      form_data = %MultipleChoiceForm{}

      form_params = %{
        "title" => "Multiple Field Test",
        "preferences" => ["email_notifications", "sms_alerts"],
        "tags" => ["elixir", "phoenix"]
      }

      changeset = MultipleChoiceForm.changeset(form_data, form_params)
      base_form = FormData.to_form(changeset, as: :multiple_choice_form)

      # Simulate what happens when Phoenix.HTML creates field names with []
      # This is what would happen in the HTML when multiple=true
      modified_form = %{
        base_form
        | params:
            Map.merge(base_form.params, %{
              "preferences[]" => ["email_notifications", "sms_alerts"],
              "tags[]" => ["elixir", "phoenix"]
            })
      }

      encoded = Encoder.encode(modified_form)

      # The encoder should handle [] field names correctly
      # by looking for the base field name when [] suffix is present
      assert encoded.values.preferences == ["email_notifications", "sms_alerts"]
      assert encoded.values.tags == ["elixir", "phoenix"]
    end

    test "real Phoenix form behavior simulation" do
      # This simulates what happens in a real Phoenix controller
      # where Phoenix.Controller.params would normalize "field[]" params

      # Simulate incoming controller params (what Phoenix would give us)
      controller_params = %{
        "multiple_choice_form" => %{
          "title" => "Real Form Test",
          "preferences" => ["email_notifications", "sms_alerts"],
          "tags" => ["elixir", "phoenix"]
        }
      }

      form_params = controller_params["multiple_choice_form"]
      form_data = %MultipleChoiceForm{}

      # This is how forms typically work in Phoenix controllers
      changeset = MultipleChoiceForm.changeset(form_data, form_params)
      form = FormData.to_form(changeset, as: :multiple_choice_form)

      encoded = Encoder.encode(form)

      assert encoded.values == %{
               id: nil,
               title: "Real Form Test",
               preferences: ["email_notifications", "sms_alerts"],
               tags: ["elixir", "phoenix"]
               # internal_data excluded by encoder
             }
    end
  end
end

defmodule LiveVue.EncoderFormTest do
  use ExUnit.Case

  import Ecto.Changeset
  import Phoenix.Component, only: [to_form: 2]

  alias LiveVue.Encoder
  alias Phoenix.HTML.FormData

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
      embeds_many(:items, Simple)
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
      changeset = Simple.changeset(simple, attrs)
      form = FormData.to_form(changeset, as: :simple)

      encoded = Encoder.encode(form)

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
      changeset = Simple.changeset(simple, attrs)
      form = FormData.to_form(changeset, as: :simple)

      encoded = Encoder.encode(form)

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
      changeset = Simple.changeset(simple, attrs)
      form = FormData.to_form(changeset, as: :simple)

      encoded = Encoder.encode(form)

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
      changeset = Simple.changeset(simple, attrs)
      form = FormData.to_form(changeset, as: :simple)

      encoded = Encoder.encode(form)

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

      changeset = Complex.changeset(complex, attrs)
      form = FormData.to_form(changeset, as: :complex)

      encoded = Encoder.encode(form)

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

      changeset = Complex.changeset(complex, attrs)
      form = FormData.to_form(changeset, as: :complex)

      encoded = Encoder.encode(form)

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

      changeset = Complex.changeset(complex, attrs)
      form = FormData.to_form(changeset, as: :complex)

      encoded = Encoder.encode(form)

      assert encoded.valid == false

      assert encoded.values == %{
               id: nil,
               title: nil,
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
                 title: nil,
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

      changeset = CustomFormData.changeset(custom_data, attrs)
      form = FormData.to_form(changeset, as: :custom)

      encoded = Encoder.encode(form)

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
      changeset = Simple.changeset(simple, attrs)
      form = FormData.to_form(changeset, as: :simple)

      encoded = Encoder.encode(form)

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

      complex_changeset = Complex.changeset(complex, complex_attrs)
      complex_form = FormData.to_form(complex_changeset, as: :complex)
      complex_encoded = Encoder.encode(complex_form)

      # Private_data field not in values
      refute Map.has_key?(complex_encoded.values, :private_data)
      assert complex_encoded.values.title == "Test"
    end
  end

  describe "form error handling edge cases" do
    test "handles multiple errors on single field" do
      simple = %Simple{}
      # Invalid age and score to trigger multiple validation errors potentially
      attrs = %{name: nil, age: -10, score: 200}
      changeset = Simple.changeset(simple, attrs)
      form = FormData.to_form(changeset, as: :simple)

      encoded = Encoder.encode(form)

      assert encoded.valid == false

      assert encoded.values == %{
               id: nil,
               name: nil,
               age: -10,
               active: nil,
               tags: nil,
               score: 200
             }

      # Check that errors exist for invalid fields
      assert Map.has_key?(encoded.errors, :name)
      assert Map.has_key?(encoded.errors, :age)
      assert Map.has_key?(encoded.errors, :score)
      assert is_list(encoded.errors.name)
    end

    test "encodes form with deeply nested validation errors" do
      complex = %Complex{}

      attrs = %{
        title: "Valid Title",
        nested: %{
          # Invalid - empty title
          title: "",
          items: [
            # Invalid items
            %{name: nil, age: -5}
          ]
        }
      }

      changeset = Complex.changeset(complex, attrs)
      form = FormData.to_form(changeset, as: :complex)

      encoded = Encoder.encode(form)

      # Basic structure should be intact even with nested validation errors
      assert encoded.values == %{
               id: nil,
               title: "Valid Title",
               nested: %{
                 id: nil,
                 title: nil,
                 nested: nil,
                 items: [
                   %{
                     id: nil,
                     name: nil,
                     age: -5,
                     active: nil,
                     tags: nil,
                     score: nil
                   }
                 ]
               },
               items: []
             }

      # The form itself might be invalid due to nested errors
      # (depends on Ecto changeset behavior with nested validations)
    end
  end

  describe "form parameter handling with real changesets" do
    test "handles changeset with existing data and new params" do
      # Start with existing simple data
      simple = %Simple{name: "Original", secret: "original_secret", age: 20}

      # Apply new parameters
      attrs = %{name: "Updated", secret: "updated_secret", age: 25, active: true}
      changeset = Simple.changeset(simple, attrs)
      form = FormData.to_form(changeset, as: :simple)

      encoded = Encoder.encode(form)

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
      changeset = Simple.changeset(simple, attrs)
      form = FormData.to_form(changeset, as: :simple)

      encoded = Encoder.encode(form)

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

  describe "form validation behavior" do
    test "nested embedded forms validation affects parent form validity" do
      complex = %Complex{}

      attrs = %{
        title: "Valid Parent",
        nested: %{
          # Invalid - empty title in nested struct
          title: ""
        },
        items: [
          %{name: "Valid item"},
          # Invalid item
          %{name: nil}
        ]
      }

      encoded =
        complex
        |> Complex.changeset(attrs)
        |> FormData.to_form(as: :complex)
        |> Encoder.encode()

      assert encoded.values == %{
               id: nil,
               title: "Valid Parent",
               nested: %{
                 id: nil,
                 title: nil,
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
                   age: nil,
                   active: nil,
                   tags: nil,
                   score: nil
                 }
               ]
             }

      assert encoded.valid == false

      assert encoded.errors == %{
               nested: %{
                 title: ["can't be blank"]
               },
               items: [
                 nil,
                 %{name: ["can't be blank"]}
               ]
             }
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

    test "encodes form with nil values" do
      form_data = %{
        "name" => nil,
        "email" => nil,
        "bio" => nil,
        "active" => nil
      }

      form = to_form(form_data, as: :nullable_form)
      encoded = Encoder.encode(form)

      assert encoded.values == %{
               "name" => nil,
               "email" => nil,
               "bio" => nil,
               "active" => nil
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
end

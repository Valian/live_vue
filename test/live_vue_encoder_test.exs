defmodule LiveVue.EncoderTest do
  use ExUnit.Case
  alias LiveVue.Encoder

  describe "primitive types" do
    test "encodes integers" do
      assert Encoder.encode(42) == 42
      assert Encoder.encode(0) == 0
      assert Encoder.encode(-123) == -123
    end

    test "encodes floats" do
      assert Encoder.encode(3.14) == 3.14
      assert Encoder.encode(0.0) == 0.0
      assert Encoder.encode(-2.5) == -2.5
    end

    test "encodes strings" do
      assert Encoder.encode("hello") == "hello"
      assert Encoder.encode("") == ""
      assert Encoder.encode("with spaces") == "with spaces"
    end

    test "encodes booleans and nil" do
      assert Encoder.encode(true) == true
      assert Encoder.encode(false) == false
      assert Encoder.encode(nil) == nil
    end

    test "encodes atoms as atoms" do
      assert Encoder.encode(:hello) == :hello
      assert Encoder.encode(:world) == :world
      assert Encoder.encode(:"with spaces") == :"with spaces"
    end
  end

  describe "complex types" do
    test "encodes lists recursively" do
      assert Encoder.encode([1, 2, 3]) == [1, 2, 3]
      assert Encoder.encode(["a", "b", "c"]) == ["a", "b", "c"]
      assert Encoder.encode([]) == []

      # Test nested lists
      assert Encoder.encode([1, [2, 3], 4]) == [1, [2, 3], 4]

      # Test mixed types
      assert Encoder.encode([1, "hello", :world, true]) == [1, "hello", :world, true]
    end

    test "encodes maps recursively" do
      assert Encoder.encode(%{a: 1, b: 2}) == %{a: 1, b: 2}
      assert Encoder.encode(%{}) == %{}

      # Test string keys
      assert Encoder.encode(%{"a" => 1, "b" => 2}) == %{"a" => 1, "b" => 2}

      # Test mixed key types
      assert Encoder.encode(%{:a => 1, "b" => 2}) == %{:a => 1, "b" => 2}

      # Test nested maps
      nested = %{
        user: %{name: "John", age: 30},
        items: [1, 2, 3]
      }

      expected = %{
        user: %{name: "John", age: 30},
        items: [1, 2, 3]
      }

      assert Encoder.encode(nested) == expected
    end
  end

  defmodule TestUser do
    @derive LiveVue.Encoder
    defstruct [:name, :age, :email]
  end

  defmodule TestUserWithPassword do
    @derive LiveVue.Encoder
    defstruct [:name, :password, :email]
  end

  defmodule TestAccount do
    @derive LiveVue.Encoder
    defstruct [:user, :balance]
  end

  defmodule Company do
    @derive LiveVue.Encoder
    defstruct [:name, :employees, :config]
  end

  defmodule Employee do
    @derive LiveVue.Encoder
    defstruct [:name, :role, :skills]
  end

  defmodule EmptyStruct do
    @derive LiveVue.Encoder
    defstruct []
  end

  defmodule AtomStruct do
    @derive LiveVue.Encoder
    defstruct [:status, :type]
  end

  # Test structs with deriving
  defmodule DerivedUser do
    @derive LiveVue.Encoder
    defstruct [:name, :age, :email]
  end

  defmodule DerivedUserOnly do
    @derive {LiveVue.Encoder, only: [:name, :age]}
    defstruct [:name, :age, :email, :password]
  end

  defmodule DerivedUserExcept do
    @derive {LiveVue.Encoder, except: [:password]}
    defstruct [:name, :age, :email, :password]
  end

  defmodule NotDerivedUser do
    defstruct [:name, :age, :email, :password]
  end

  describe "structs" do
    test "encodes structs to maps" do
      user = %TestUser{name: "John", age: 30, email: "john@example.com"}

      expected = %{
        name: "John",
        age: 30,
        email: "john@example.com"
      }

      assert Encoder.encode(user) == expected
    end

    test "encodes structs with nil values" do
      user = %TestUser{name: "John", age: nil, email: "john@example.com"}

      expected = %{
        name: "John",
        age: nil,
        email: "john@example.com"
      }

      assert Encoder.encode(user) == expected
    end

    test "structs are fully converted to maps (no __struct__ field)" do
      user = %TestUser{name: "John", age: 30, email: "john@example.com"}
      encoded = Encoder.encode(user)

      refute Map.has_key?(encoded, :__struct__)
      refute Map.has_key?(encoded, "__struct__")
    end

    test "encodes nested structs" do
      user = %TestUser{name: "John", age: 30, email: "john@example.com"}
      account = %TestAccount{user: user, balance: 1000}

      expected = %{
        user: %{
          name: "John",
          age: 30,
          email: "john@example.com"
        },
        balance: 1000
      }

      assert Encoder.encode(account) == expected
    end

    test "encodes structs in lists" do
      users = [
        %TestUser{name: "John", age: 30, email: "john@example.com"},
        %TestUser{name: "Jane", age: 25, email: "jane@example.com"}
      ]

      expected = [
        %{name: "John", age: 30, email: "john@example.com"},
        %{name: "Jane", age: 25, email: "jane@example.com"}
      ]

      assert Encoder.encode(users) == expected
    end

    test "encodes structs in maps" do
      data = %{
        admin: %TestUser{name: "John", age: 30, email: "john@example.com"},
        user: %TestUser{name: "Jane", age: 25, email: "jane@example.com"}
      }

      expected = %{
        admin: %{name: "John", age: 30, email: "john@example.com"},
        user: %{name: "Jane", age: 25, email: "jane@example.com"}
      }

      assert Encoder.encode(data) == expected
    end
  end

  describe "deeply nested structures" do
    test "encodes complex nested structures" do
      company = %Company{
        name: "Tech Corp",
        employees: [
          %Employee{name: "Alice", role: :developer, skills: ["elixir", "phoenix"]},
          %Employee{name: "Bob", role: :designer, skills: ["figma", "css"]}
        ],
        config: %{
          remote: true,
          timezone: :utc,
          benefits: ["health", "dental"]
        }
      }

      expected = %{
        name: "Tech Corp",
        employees: [
          %{
            name: "Alice",
            role: :developer,
            skills: ["elixir", "phoenix"]
          },
          %{
            name: "Bob",
            role: :designer,
            skills: ["figma", "css"]
          }
        ],
        config: %{
          remote: true,
          timezone: :utc,
          benefits: ["health", "dental"]
        }
      }

      assert Encoder.encode(company) == expected
    end
  end

  describe "edge cases" do
    test "handles empty structs" do
      assert Encoder.encode(%EmptyStruct{}) == %{}
    end

    test "handles structs with atom values" do
      struct = %AtomStruct{status: :active, type: :premium}
      expected = %{status: :active, type: :premium}

      assert Encoder.encode(struct) == expected
    end
  end

  describe "deriving functionality" do
    test "derives encoder for all fields" do
      user = %DerivedUser{name: "John", age: 30, email: "john@example.com"}

      expected = %{
        name: "John",
        age: 30,
        email: "john@example.com"
      }

      assert Encoder.encode(user) == expected
    end

    test "derives encoder with only specified fields" do
      user = %DerivedUserOnly{name: "John", age: 30, email: "john@example.com", password: "secret"}

      expected = %{
        name: "John",
        age: 30
      }

      assert Encoder.encode(user) == expected
    end

    test "derives encoder excluding specified fields" do
      user = %DerivedUserExcept{name: "John", age: 30, email: "john@example.com", password: "secret"}

      expected = %{
        name: "John",
        age: 30,
        email: "john@example.com"
      }

      assert Encoder.encode(user) == expected
    end

    test "non-derived structs raise protocol error" do
      struct = %NotDerivedUser{name: "John", age: 30, email: "john@example.com"}

      assert_raise Protocol.UndefinedError, ~r/LiveVue.Encoder protocol must always be explicitly implemented/, fn ->
        Encoder.encode(struct)
      end
    end
  end

  describe "additional primitive types" do
    test "encodes date and time types" do
      date = ~D[2023-01-01]
      time = ~T[12:00:00]
      naive_datetime = ~N[2023-01-01 12:00:00]
      datetime = DateTime.from_naive!(naive_datetime, "Etc/UTC")

      assert Encoder.encode(date) == date
      assert Encoder.encode(time) == time
      assert Encoder.encode(naive_datetime) == naive_datetime
      assert Encoder.encode(datetime) == datetime
    end

    test "encodes tuples as tuples" do
      tuple = {:ok, "success", 42}
      assert Encoder.encode(tuple) == {:ok, "success", 42}
    end

    test "encodes system types as themselves" do
      pid = self()
      encoded_pid = Encoder.encode(pid)

      assert encoded_pid == pid
    end

    test "encodes functions as themselves" do
      fun = fn x -> x + 1 end
      encoded_fun = Encoder.encode(fun)

      assert encoded_fun == fun
    end
  end
end

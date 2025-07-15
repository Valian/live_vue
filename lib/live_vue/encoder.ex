defprotocol LiveVue.Encoder do
  @moduledoc """
  Protocol for encoding values to JSON for LiveVue.

  This protocol is used to safely transform structs into plain maps before
  calculating JSON patches. It ensures that struct fields are explicitly
  exposed and prevents accidental exposure of sensitive data.

  It's very similar to Jason.Encoder, but it's converting structs to maps instead of strings.

  ## Deriving

  The protocol allows leveraging Elixir's `@derive` feature to simplify protocol
  implementation in trivial cases. Accepted options are:

  * `:only` - encodes only values of specified keys.
  * `:except` - encodes all struct fields except specified keys.

  By default all keys except the `:__struct__` key are encoded.

  ## Example

  Let's assume a presence of the following struct:

      defmodule User do
        defstruct [:name, :email, :password]
      end

  If we were to call `@derive LiveVue.Encoder` just before `defstruct`, an
  implementation would be generated that encodes all fields except `:__struct__`:

      @derive LiveVue.Encoder
      defmodule User do
        defstruct [:name, :email, :password]
      end

  If we called `@derive {LiveVue.Encoder, only: [:name, :email]}`, only the
  specified fields would be encoded:

      @derive {LiveVue.Encoder, only: [:name, :email]}
      defmodule User do
        defstruct [:name, :email, :password]
      end

  If we called `@derive {LiveVue.Encoder, except: [:password]}`, all fields
  except the specified ones would be encoded:

      @derive {LiveVue.Encoder, except: [:password]}
      defmodule User do
        defstruct [:name, :email, :password]
      end

  ## Deriving outside of the module

  If you don't own the struct you want to encode, you may use Protocol.derive/3 placed outside of any module:

  Protocol.derive(LiveVue.Encoder, User, only: [...])

  ## Custom implementations

  You may define your own implementation for the struct:

  defimpl LiveVue.Encoder, for: User do
    def encode(struct, opts) do
      struct
      |> Map.take([:first, :second])
      |> LiveVue.Encoder.encode(opts)
    end
  end
  """

  @type t :: term
  @type opts :: Keyword.t()
  @fallback_to_any true

  @doc """
  Encodes a value to one of the primitive types.
  """
  @spec encode(t, opts) :: any()
  def encode(value, opts \\ [])
end

# Primitive types that are already JSON serializable
defimpl LiveVue.Encoder, for: Integer do
  def encode(value, _opts), do: value
end

defimpl LiveVue.Encoder, for: Float do
  def encode(value, _opts), do: value
end

defimpl LiveVue.Encoder, for: BitString do
  def encode(value, _opts), do: value
end

defimpl LiveVue.Encoder, for: Atom do
  def encode(atom, _opts), do: atom
end

# Complex types that need recursive encoding
defimpl LiveVue.Encoder, for: List do
  def encode(list, opts) do
    Enum.map(list, &LiveVue.Encoder.encode(&1, opts))
  end
end

defimpl LiveVue.Encoder, for: Map do
  def encode(map, opts) do
    Enum.into(map, %{}, fn {key, value} ->
      {key, LiveVue.Encoder.encode(value, opts)}
    end)
  end
end

# Date and time types - Jason encoder handles them
defimpl LiveVue.Encoder, for: [Date, Time, NaiveDateTime, DateTime] do
  def encode(value, _opts) do
    value
  end
end

# Default implementation for structs - convert to map and encode recursively
defimpl LiveVue.Encoder, for: Any do
  defmacro __deriving__(module, struct, opts) do
    fields = fields_to_encode(struct, opts)

    quote do
      defimpl LiveVue.Encoder, for: unquote(module) do
        def encode(struct, opts) do
          struct
          |> Map.take(unquote(fields))
          |> LiveVue.Encoder.encode(opts)
        end
      end
    end
  end

  def encode(%{__struct__: module} = struct, _opts) do
    raise Protocol.UndefinedError,
      protocol: @protocol,
      value: struct,
      description: """
      LiveVue.Encoder protocol must always be explicitly implemented.

      It's used to encode structs to JSON for LiveVue. It's very similar to Jason.Encoder,
      but it's converting structs to maps so LiveVue can diff them correctly.

      If you own the struct, you can derive the implementation specifying \
      which fields should be encoded:

          @derive {LiveVue.Encoder, only: [...]}
          defmodule #{inspect(module)} do
            defstruct ...
          end

      It is also possible to encode all fields, although this should be \
      used carefully to avoid accidentally leaking private information \
      when new fields are added:

          @derive LiveVue.Encoder
          defmodule #{inspect(module)} do
            defstruct ...
          end

      If you don't own the struct you want to encode, \
      you may use Protocol.derive/3 placed outside of any module:

          Protocol.derive(LiveVue.Encoder, #{inspect(module)}, only: [...])
          Protocol.derive(LiveVue.Encoder, #{inspect(module)})

      Nothing prevents you from defining your own implementation for the struct:

      defimpl LiveVue.Encoder, for: #{inspect(module)} do
        def encode(struct, opts) do
          struct
          |> Map.take([:first, :second])
          |> LiveVue.Encoder.encode(opts)
        end
      end
      """
  end

  def encode(value, _opts) do
    # For any other type, try to pass through as-is
    # This covers things like PIDs, references, etc.
    value
  end

  defp fields_to_encode(struct, opts) do
    fields = Map.keys(struct)

    cond do
      only = Keyword.get(opts, :only) ->
        case only -- fields do
          [] ->
            only

          error_keys ->
            raise ArgumentError,
                  ":only specified keys (#{inspect(error_keys)}) that are not defined in defstruct: " <>
                    "#{inspect(fields -- [:__struct__])}"
        end

      except = Keyword.get(opts, :except) ->
        case except -- fields do
          [] ->
            fields -- [:__struct__ | except]

          error_keys ->
            raise ArgumentError,
                  ":except specified keys (#{inspect(error_keys)}) that are not defined in defstruct: " <>
                    "#{inspect(fields -- [:__struct__])}"
        end

      true ->
        fields -- [:__struct__]
    end
  end
end

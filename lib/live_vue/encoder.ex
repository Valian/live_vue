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

      defmodule User do
        @derive LiveVue.Encoder
        defstruct [:name, :email, :password]
      end

  If we called `@derive {LiveVue.Encoder, only: [:name, :email]}`, only the
  specified fields would be encoded:

      defmodule User do
        @derive {LiveVue.Encoder, only: [:name, :email]}
        defstruct [:name, :email, :password]
      end

  If we called `@derive {LiveVue.Encoder, except: [:password]}`, all fields
  except the specified ones would be encoded:

      defmodule User do
        @derive {LiveVue.Encoder, except: [:password]}
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
    Map.new(map, fn {key, value} ->
      {key, LiveVue.Encoder.encode(value, opts)}
    end)
  end
end

# Date and time types - Jason encoder handles them
defimpl LiveVue.Encoder, for: [Date, Time, NaiveDateTime, DateTime] do
  def encode(value, _opts) do
    # otherwise diff is comparing tuples, and that's not what we want
    @for.to_iso8601(value)
  end
end

defimpl LiveVue.Encoder, for: Phoenix.HTML.Form do
  def encode(%Phoenix.HTML.Form{} = form, opts) do
    LiveVue.Encoder.encode(
      %{
        name: form.name,
        values: encode_form_values(form),
        errors: encode_form_errors(form) || %{},
        valid: form.source.valid?
      },
      opts
    )
  end

  def encode_form_values(%{impl: Phoenix.HTML.FormData.Ecto.Changeset} = form) do
    form.hidden
    |> Map.new()
    |> Map.merge(Map.new(form.params))
    |> Map.merge(form.data)
  end

  def encode_form_errors(%{impl: Phoenix.HTML.FormData.Ecto.Changeset} = form) do
    errors =
      for {field, error} <- form.errors, into: %{} do
        case error do
          error when is_list(error) ->
            {field, Enum.map(error, &translate_error/1)}

          error ->
            {field, List.wrap(translate_error(error))}
        end
      end

    # TODO - In my project I'm using Ash so I don't have yet an implementation
    # of nested error serialization for Ecto-backed forms.
    # errors =
    #   for {field, form_settings} <- ash_form.form_keys, into: errors do
    #     case form_settings[:type] do
    #       :single ->
    #         {field, encode_form_errors(impl.to_form(ash_form.forms[field], []))}

    #       :list ->
    #         field_errors =
    #           ash_form.forms[field]
    #           |> Kernel.||([])
    #           |> Enum.map(fn f -> encode_form_errors(impl.to_form(f, [])) end)

    #         # if there are no errors, return nil
    #         if Enum.all?(field_errors, &(&1 == nil)) do
    #           {field, nil}
    #         else
    #           {field, field_errors}
    #         end
    #     end
    #   end

    # let's leave only keys with errors. If none, let's return nil.
    errors = for {field, error} <- errors, error != nil, into: %{}, do: {field, error}
    if errors == %{}, do: nil, else: errors
  end

  defp translate_error({msg, opts}) do
    backend = Application.get_env(:live_vue, :gettext_backend, nil)
    count = opts[:count]

    cond do
      backend == nil ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)

      count != nil ->
        Gettext.dngettext(backend, "errors", msg, msg, count, opts)

      true ->
        Gettext.dgettext(backend, "errors", msg, opts)
    end
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

          defmodule #{inspect(module)} do
            @derive {LiveVue.Encoder, only: [...]}
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

# Phoenix LiveView Upload structs
# Explicit implementation of LiveVue.Encoder for UploadConfig
defimpl LiveVue.Encoder, for: Phoenix.LiveView.UploadConfig do
  def encode(%Phoenix.LiveView.UploadConfig{} = struct, opts) do
    errors =
      Enum.map(struct.errors, fn {key, value} ->
        %{ref: key, error: LiveVue.Encoder.encode(value, opts)}
      end)

    entries =
      Enum.map(struct.entries, fn entry ->
        encoded = LiveVue.Encoder.encode(entry, opts)
        entry_errors = errors |> Enum.filter(&(&1.ref == entry.ref)) |> Enum.map(& &1.error)
        Map.put(encoded, :errors, entry_errors)
      end)

    LiveVue.Encoder.encode(
      %{
        ref: struct.ref,
        name: struct.name,
        accept: struct.accept,
        max_entries: struct.max_entries,
        auto_upload: struct.auto_upload?,
        entries: entries,
        errors: errors
      },
      opts
    )
  end
end

# Explicit implementation of LiveVue.Encoder for UploadEntry
defimpl LiveVue.Encoder, for: Phoenix.LiveView.UploadEntry do
  def encode(%Phoenix.LiveView.UploadEntry{} = struct, opts) do
    LiveVue.Encoder.encode(
      %{
        ref: struct.ref,
        client_name: struct.client_name,
        client_size: struct.client_size,
        client_type: struct.client_type,
        progress: struct.progress,
        done: struct.done?,
        valid: struct.valid?,
        preflighted: struct.preflighted?
      },
      opts
    )
  end
end

# Explicit implementation of LiveVue.Encoder for LiveStream
defimpl LiveVue.Encoder, for: Phoenix.LiveView.LiveStream do
  def encode(%Phoenix.LiveView.LiveStream{} = stream, opts) do
    # Use the LiveStream's own Enumerable protocol implementation
    # which handles deduplication and ordering correctly
    consumable_stream = %{stream | consumable?: true}

    Enum.map(consumable_stream, fn {dom_id, item} ->
      Map.put(LiveVue.Encoder.encode(item, opts), :__dom_id, dom_id)
    end)
  end
end

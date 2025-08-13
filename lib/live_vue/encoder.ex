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
        values: encode_form_values(form, opts),
        errors: encode_form_errors(form) || %{},
        valid: get_form_validity(form)
      },
      opts
    )
  end

  defp get_form_validity(%{source: %{valid?: valid}}), do: valid
  defp get_form_validity(_), do: true

  if Code.ensure_loaded?(Ecto) do
    defp convert_embedded_changesets(data, types) do
      Enum.reduce(types, data, fn {field, type_info}, acc ->
        case type_info do
          {tag, %{cardinality: _}} when tag in [:embed, :assoc] ->
            # This is an embedded field - convert changesets to structs
            converted_value = acc |> Map.get(field) |> convert_changeset_to_struct()
            Map.put(acc, field, converted_value)

          _ ->
            # Regular field - no conversion needed
            acc
        end
      end)
    end

    defp convert_changeset_to_struct(nil), do: nil
    defp convert_changeset_to_struct(%Ecto.Association.NotLoaded{}), do: nil

    defp convert_changeset_to_struct(%Ecto.Changeset{} = changeset) do
      # Convert changeset to struct recursively
      base_data =
        if is_struct(changeset.data) do
          changeset.data |> Map.from_struct() |> Map.delete(:__meta__)
        else
          changeset.data
        end

      merged_data = Map.merge(base_data, changeset.changes)
      converted_data = convert_embedded_changesets(merged_data, changeset.types)

      if is_struct(changeset.data) do
        struct(changeset.data.__struct__, converted_data)
      else
        converted_data
      end
    end

    defp convert_changeset_to_struct(value) when is_list(value) do
      # Handle embeds_many
      Enum.map(value, &convert_changeset_to_struct/1)
    end

    defp convert_changeset_to_struct(value) do
      # For anything else (structs, maps, primitives), pass through as-is
      value
    end

    def encode_form_values(%{impl: Phoenix.HTML.FormData.Ecto.Changeset} = form, opts) do
      # Create a struct with the changeset data and changes applied
      merged_struct =
        if is_struct(form.data) do
          struct_data = form.data |> Map.from_struct() |> Map.delete(:__meta__)
          merged_data = Map.merge(struct_data, form.source.changes)

          # Convert any embedded changesets to structs recursively
          converted_data = convert_embedded_changesets(merged_data, form.source.types)

          struct(form.data.__struct__, converted_data)
        else
          Map.merge(form.data, form.source.changes)
        end

      # Add hidden fields and encode the result
      form.hidden |> Map.new() |> Map.merge(LiveVue.Encoder.encode(merged_struct, opts))
    end
  end

  # Fallback for other form implementations (like to_form backed by maps)
  def encode_form_values(form, opts) do
    base_values =
      form.hidden
      |> Map.new()
      |> Map.merge(form.data)
      |> Map.merge(Map.new(form.params))

    # For non-changeset forms, we don't have type information for embeds
    # so just encode the values as-is
    LiveVue.Encoder.encode(base_values, opts)
  end

  if Code.ensure_loaded?(Ecto) do
    defp collect_embedded_errors(%Ecto.Changeset{} = changeset) do
      Enum.reduce(changeset.changes, %{}, fn {field, value}, acc ->
        case {Map.get(changeset.types, field), value} do
          {{:embed, _}, %Ecto.Changeset{} = embed_changeset} ->
            # Single embedded changeset
            embed_errors = collect_changeset_errors(embed_changeset)
            if embed_errors == %{}, do: acc, else: Map.put(acc, field, embed_errors)

          {{:embed, _}, embed_changesets} when is_list(embed_changesets) ->
            # List of embedded changesets
            list_errors =
              Enum.map(embed_changesets, fn embed_changeset ->
                case embed_changeset do
                  %Ecto.Changeset{} ->
                    embed_errors = collect_changeset_errors(embed_changeset)
                    if embed_errors == %{}, do: nil, else: embed_errors

                  _ ->
                    nil
                end
              end)

            # Only include the field if there are any errors in the list
            if Enum.all?(list_errors, &is_nil/1), do: acc, else: Map.put(acc, field, list_errors)

          _ ->
            acc
        end
      end)
    end

    defp collect_changeset_errors(%Ecto.Changeset{} = changeset) do
      # Collect direct errors from this changeset
      direct_errors =
        for {field, error} <- changeset.errors, into: %{} do
          case error do
            error when is_list(error) ->
              {field, Enum.map(error, &translate_error/1)}

            error ->
              {field, List.wrap(translate_error(error))}
          end
        end

      # Collect errors from nested embedded changesets
      nested_errors = collect_embedded_errors(changeset)

      # Merge direct and nested errors
      Map.merge(direct_errors, nested_errors)
    end

    def encode_form_errors(%{impl: Phoenix.HTML.FormData.Ecto.Changeset} = form) do
      # Collect top-level errors
      direct_errors =
        for {field, error} <- form.source.errors, into: %{} do
          case error do
            error when is_list(error) ->
              {field, Enum.map(error, &translate_error/1)}

            error ->
              {field, List.wrap(translate_error(error))}
          end
        end

      # Collect errors from embedded changesets
      embedded_errors = collect_embedded_errors(form.source)

      # Merge direct errors with embedded errors
      all_errors = Map.merge(direct_errors, embedded_errors)

      # let's leave only keys with errors. If none, let's return nil.
      errors = for {field, error} <- all_errors, error != nil, into: %{}, do: {field, error}
      if errors == %{}, do: nil, else: errors
    end
  end

  # Fallback for other form implementations (like test mocks)
  def encode_form_errors(form) do
    errors =
      for {field, error} <- form.errors, into: %{} do
        case error do
          error when is_list(error) ->
            {field, Enum.map(error, &translate_error/1)}

          error ->
            {field, List.wrap(translate_error(error))}
        end
      end

    # let's leave only keys with errors. If none, let's return nil.
    errors = for {field, error} <- errors, error != nil, into: %{}, do: {field, error}
    if errors == %{}, do: nil, else: errors
  end

  defp translate_error({msg, opts}) do
    backend = Application.get_env(:live_vue, :gettext_backend, nil)
    count = opts[:count]

    cond do
      backend == nil or not Code.ensure_loaded?(Gettext) ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)

      count != nil and Code.ensure_loaded?(Gettext) ->
        apply(Gettext, :dngettext, [backend, "errors", msg, msg, count, opts])

      Code.ensure_loaded?(Gettext) ->
        apply(Gettext, :dgettext, [backend, "errors", msg, opts])

      true ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
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

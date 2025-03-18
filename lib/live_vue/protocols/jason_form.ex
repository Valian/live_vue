defimpl Jason.Encoder, for: Phoenix.HTML.Form do
  def encode(%Phoenix.HTML.Form{} = form, opts) do
    Jason.Encode.map(
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
        # TODO - handle it better somehow?
        msg

      count != nil ->
        Gettext.dngettext(backend, "errors", msg, msg, count, opts)

      true ->
        Gettext.dgettext(backend, "errors", msg, opts)
    end
  end
end

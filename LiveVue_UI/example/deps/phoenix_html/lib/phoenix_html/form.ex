defmodule Phoenix.HTML.Form do
  # TODO: Remove action field from Form
  # TODO: Keep only map implementation for form data

  @moduledoc ~S"""
  Define a `Phoenix.HTML.Form` struct and functions to interact with it.

  ## Access behaviour

  The `Phoenix.HTML.Form` struct implements the `Access` behaviour.
  When you do `form[field]`, it returns a `Phoenix.HTML.FormField`
  struct with the `id`, `name`, `value`, and `errors` prefilled.

  The field name can be either an atom or a string. If it is an atom,
  it assumes the form keeps both data and errors as atoms. If it is a
  string, it considers that data and errors are stored as strings for said
  field. Forms backed by an `Ecto.Changeset` only support atom field names.

  It is possible to "access" fields which do not exist in the source data
  structure. A `Phoenix.HTML.FormField` struct will be dynamically created
  with some attributes such as `name` and `id` populated.
  """

  alias Phoenix.HTML.Form
  import Phoenix.HTML
  import Phoenix.HTML.Tag

  @doc """
  Defines the Phoenix.HTML.Form struct.

  Its fields are:

    * `:source` - the data structure given to `form_for/4` that
      implements the form data protocol

    * `:impl` - the module with the form data protocol implementation.
      This is used to avoid multiple protocol dispatches.

    * `:id` - the id to be used when generating input fields

    * `:index` - the index of the struct in the form

    * `:name` - the name to be used when generating input fields

    * `:data` - the field used to store lookup data

    * `:params` - the parameters associated with this form

    * `:hidden` - a keyword list of fields that are required to
      submit the form behind the scenes as hidden inputs

    * `:options` - a copy of the options given when creating the
      form via `form_for/4` without any form data specific key

    * `:errors` - a keyword list of errors that are associated with
      the form
  """
  defstruct source: nil,
            impl: nil,
            id: nil,
            name: nil,
            data: nil,
            action: nil,
            hidden: [],
            params: %{},
            errors: [],
            options: [],
            index: nil

  @type t :: %Form{
          source: Phoenix.HTML.FormData.t(),
          name: String.t(),
          data: %{field => term},
          action: nil | String.t() | atom(),
          params: %{binary => term},
          hidden: Keyword.t(),
          options: Keyword.t(),
          errors: [{field, term}],
          impl: module,
          id: String.t(),
          index: nil | non_neg_integer
        }

  @type field :: atom | String.t()

  @doc false
  def fetch(%Form{} = form, field) when is_atom(field) do
    fetch(form, field, Atom.to_string(field))
  end

  def fetch(%Form{} = form, field) when is_binary(field) do
    fetch(form, field, field)
  end

  def fetch(%Form{}, field) do
    raise ArgumentError,
          "accessing a form with form[field] requires the field to be an atom or a string, got: #{inspect(field)}"
  end

  defp fetch(%{errors: errors} = form, field, field_as_string) do
    {:ok,
     %Phoenix.HTML.FormField{
       errors: field_errors(errors, field),
       field: field,
       form: form,
       id: input_id(form, field_as_string),
       name: input_name(form, field_as_string),
       value: input_value(form, field)
     }}
  end

  @doc """
  Returns a value of a corresponding form field.

  The `form` should either be a `Phoenix.HTML.Form` or an atom.
  The field is either a string or an atom. If the field is given
  as an atom, it will attempt to look data with atom keys. If
  a string, it will look data with string keys.

  When a form is given, it will look for changes, then
  fallback to parameters, and finally fallback to the default
  struct/map value.

  Since the function looks up parameter values too, there is
  no guarantee that the value will have a certain type. For
  example, a boolean field will be sent as "false" as a
  parameter, and this function will return it as is. If you
  need to normalize the result of `input_value`, see
  `normalize_value/2`.
  """
  @spec input_value(t | atom, field) :: term
  def input_value(%{source: source, impl: impl} = form, field)
      when is_atom(field) or is_binary(field) do
    impl.input_value(source, form, field)
  end

  def input_value(name, _field) when is_atom(name), do: nil

  @doc """
  Returns an id of a corresponding form field.

  The form should either be a `Phoenix.HTML.Form` emitted
  by `form_for` or an atom.
  """
  @spec input_id(t | atom, field) :: String.t()
  def input_id(%{id: nil}, field), do: "#{field}"

  def input_id(%{id: id}, field) when is_atom(field) or is_binary(field) do
    "#{id}_#{field}"
  end

  def input_id(name, field) when (is_atom(name) and is_atom(field)) or is_binary(field) do
    "#{name}_#{field}"
  end

  @doc """
  Returns an id of a corresponding form field and value attached to it.

  Useful for radio buttons and inputs like multiselect checkboxes.
  """
  @spec input_id(t | atom, field, Phoenix.HTML.Safe.t()) :: String.t()
  def input_id(name, field, value) do
    {:safe, value} = html_escape(value)
    value_id = value |> IO.iodata_to_binary() |> String.replace(~r/\W/u, "_")
    input_id(name, field) <> "_" <> value_id
  end

  @doc """
  Returns a name of a corresponding form field.

  The first argument should either be a `Phoenix.HTML.Form` or an atom.

  ## Examples

      iex> Phoenix.HTML.Form.input_name(:user, :first_name)
      "user[first_name]"
  """
  @spec input_name(t | atom, field) :: String.t()
  def input_name(form_or_name, field)

  def input_name(%{name: nil}, field), do: to_string(field)

  def input_name(%{name: name}, field) when is_atom(field) or is_binary(field),
    do: "#{name}[#{field}]"

  def input_name(name, field) when (is_atom(name) and is_atom(field)) or is_binary(field),
    do: "#{name}[#{field}]"

  @doc """
  Receives two forms structs and checks if the given field changed.

  The field will have changed if either its associated value, errors,
  action, or implementation changed. This is mostly used for optimization
  engines as an extension of the `Access` behaviour.
  """
  @spec input_changed?(t, t, field()) :: boolean()
  def input_changed?(
        %Form{
          impl: impl1,
          id: id1,
          name: name1,
          errors: errors1,
          source: source1,
          action: action1
        } = form1,
        %Form{
          impl: impl2,
          id: id2,
          name: name2,
          errors: errors2,
          source: source2,
          action: action2
        } = form2,
        field
      )
      when is_atom(field) or is_binary(field) do
    impl1 != impl2 or id1 != id2 or name1 != name2 or action1 != action2 or
      field_errors(errors1, field) != field_errors(errors2, field) or
      impl1.input_value(source1, form1, field) != impl2.input_value(source2, form2, field)
  end

  @doc """
  Returns the HTML validations that would apply to
  the given field.
  """
  @spec input_validations(t, field) :: Keyword.t()
  def input_validations(%{source: source, impl: impl} = form, field)
      when is_atom(field) or is_binary(field) do
    impl.input_validations(source, form, field)
  end

  @doc """
  Normalizes an input `value` according to its input `type`.

  Certain HTML input values must be cast, or they will have idiosyncracies
  when they are rendered. The goal of this function is to encapsulate
  this logic. In particular:

    * For "datetime-local" types, it converts `DateTime` and
      `NaiveDateTime` to strings without the second precision

    * For "checkbox" types, it returns a boolean depending on
      whether the input is "true" or not

    * For "textarea", it prefixes a newline to ensure newlines
      won't be ignored on submission. This requires however
      that the textarea is rendered with no spaces after its
      content
  """
  def normalize_value("datetime-local", %struct{} = value)
      when struct in [NaiveDateTime, DateTime] do
    <<date::10-binary, ?\s, hour_minute::5-binary, _rest::binary>> = struct.to_string(value)
    {:safe, [date, ?T, hour_minute]}
  end

  def normalize_value("textarea", value) do
    {:safe, value} = html_escape(value || "")
    {:safe, [?\n | value]}
  end

  def normalize_value("checkbox", value) do
    html_escape(value) == {:safe, "true"}
  end

  def normalize_value(_type, value) do
    value
  end

  @doc """
  Returns options to be used inside a select.

  This is useful when building the select by hand.
  It expects all options and one or more select values.

  ## Examples

      options_for_select(["Admin": "admin", "User": "user"], "admin")
      #=> <option value="admin" selected>Admin</option>
      #=> <option value="user">User</option>

  Multiple selected values:

      options_for_select(["Admin": "admin", "User": "user", "Moderator": "moderator"],
        ["admin", "moderator"])
      #=> <option value="admin" selected>Admin</option>
      #=> <option value="user">User</option>
      #=> <option value="moderator" selected>Moderator</option>

  Groups are also supported:

      options_for_select(["Europe": ["UK", "Sweden", "France"], ...], nil)
      #=> <optgroup label="Europe">
      #=>   <option>UK</option>
      #=>   <option>Sweden</option>
      #=>   <option>France</option>
      #=> </optgroup>

  """
  def options_for_select(options, selected_values) do
    {:safe,
     escaped_options_for_select(
       options,
       selected_values |> List.wrap() |> Enum.map(&html_escape/1)
     )}
  end

  defp escaped_options_for_select(options, selected_values) do
    Enum.reduce(options, [], fn
      {option_key, option_value}, acc ->
        [acc | option(option_key, option_value, [], selected_values)]

      options, acc when is_list(options) ->
        {option_key, options} = Keyword.pop(options, :key)

        option_key ||
          raise ArgumentError,
                "expected :key key when building <option> from keyword list: #{inspect(options)}"

        {option_value, options} = Keyword.pop(options, :value)

        option_value ||
          raise ArgumentError,
                "expected :value key when building <option> from keyword list: #{inspect(options)}"

        [acc | option(option_key, option_value, options, selected_values)]

      option, acc ->
        [acc | option(option, option, [], selected_values)]
    end)
  end

  defp option(group_label, group_values, [], value)
       when is_list(group_values) or is_map(group_values) do
    section_options = escaped_options_for_select(group_values, value)
    option_tag("optgroup", [label: group_label], {:safe, section_options})
  end

  defp option(option_key, option_value, extra, value) do
    option_key = html_escape(option_key)
    option_value = html_escape(option_value)
    attrs = extra ++ [selected: option_value in value, value: option_value]
    option_tag("option", attrs, option_key)
  end

  defp option_tag(name, attrs, {:safe, body}) when is_binary(name) and is_list(attrs) do
    {:safe, attrs} = Phoenix.HTML.attributes_escape(attrs)
    [?<, name, attrs, ?>, body, ?<, ?/, name, ?>]
  end

  ## TODO: Remove on v4.0

  defimpl Phoenix.HTML.Safe do
    def to_iodata(%{action: action, options: options}) do
      IO.warn(
        "rendering a Phoenix.HTML.Form as part of HTML is deprecated, " <>
          "please extract the component you want to render instead. " <>
          "If you want to build a form, use form_for/3 or <.form> in LiveView"
      )

      {:safe, contents} = form_tag(action, options)
      contents
    end
  end

  @doc false
  @spec form_for(Phoenix.HTML.FormData.t(), String.t(), Keyword.t()) :: Phoenix.HTML.Form.t()
  def form_for(form_data, action, options) when is_list(options) do
    IO.warn(
      "form_for/3 without an anonymous function is deprecated. " <>
        "If you are using HEEx templates, use the new Phoenix.Component.form/1 component"
    )

    %{Phoenix.HTML.FormData.to_form(form_data, options) | action: action}
  end

  ## TODO: Move on v4.0

  @doc """
  Converts an attribute/form field into its humanize version.

      iex> humanize(:username)
      "Username"
      iex> humanize(:created_at)
      "Created at"
      iex> humanize("user_id")
      "User"

  """
  def humanize(atom) when is_atom(atom), do: humanize(Atom.to_string(atom))

  def humanize(bin) when is_binary(bin) do
    bin =
      if String.ends_with?(bin, "_id") do
        binary_part(bin, 0, byte_size(bin) - 3)
      else
        bin
      end

    bin |> String.replace("_", " ") |> :string.titlecase()
  end

  @doc false
  def form_for(form_data, action) do
    form_for(form_data, action, [])
  end

  @doc """
  Generates a form tag with a form builder and an anonymous function.

      <%= form_for @changeset, Routes.user_path(@conn, :create), fn f -> %>
        Name: <%= text_input f, :name %>
      <% end %>

  Forms may be used in two distinct scenarios:

    * with changeset data - when information to populate
      the form comes from a changeset. The changeset holds
      rich information, which helps provide conveniences

    * with map data - a simple map of parameters (such as
      `Plug.Conn.params` can be given as data to the form)

  We will explore all them below.

  Note that if you are using HEEx templates, `form_for/4` is no longer
  the preferred way to generate a form tag, and you should use
  [`Phoenix.Component.form/1`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#form/1)
  instead.

  ## With changeset data

  The entry point for defining forms in Phoenix is with
  the `form_for/4` function. For this example, we will
  use `Ecto.Changeset`, which integrates nicely with Phoenix
  forms via the `phoenix_ecto` package.

  Imagine you have the following action in your controller:

      def new(conn, _params) do
        changeset = User.changeset(%User{})
        render conn, "new.html", changeset: changeset
      end

  where `User.changeset/2` is defined as follows:

      def changeset(user, params \\ %{}) do
        Ecto.Changeset.cast(user, params, [:name, :age])
      end

  Now a `@changeset` assign is available in views which we
  can pass to the form:

      <%= form_for @changeset, Routes.user_path(@conn, :create), fn f -> %>
        <label>
          Name: <%= text_input f, :name %>
        </label>

        <label>
          Age: <%= select f, :age, 18..100 %>
        </label>

        <%= submit "Submit" %>
      <% end %>

  `form_for/4` receives the `Ecto.Changeset` and converts it
  to a form, which is passed to the function as the argument
  `f`. All the remaining functions in this module receive
  the form and automatically generate the input fields, often
  by extracting information from the given changeset. For example,
  if the user had a default value for age set, it will
  automatically show up as selected in the form.

  ### A note on `:errors`

  Even if `changeset.errors` is non-empty, errors will not be displayed in a
  form if [the changeset
  `:action`](https://hexdocs.pm/ecto/Ecto.Changeset.html#module-changeset-actions)
  is `nil` or `:ignore`.

  This is useful for things like validation hints on form fields, e.g. an empty
  changeset for a new form. That changeset isn't valid, but we don't want to
  show errors until an actual user action has been performed.

  For example, if the user submits and a `Repo.insert/1` is called and fails on
  changeset validation, the action will be set to `:insert` to show that an
  insert was attempted, and the presence of that action will cause errors to be
  displayed. The same is true for Repo.update/delete.

  If you want to show errors manually you can also set the action yourself,
  either directly on the `Ecto.Changeset` struct field or by using
  `Ecto.Changeset.apply_action/2`. Since the action can be arbitrary, you can
  set it to `:validate` or anything else to avoid giving the impression that a
  database operation has actually been attempted.

  ## With map data

  `form_for/4` expects as first argument any data structure that
  implements the `Phoenix.HTML.FormData` protocol. By default,
  Phoenix.HTML implements this protocol for `Map`.

  This is useful when you are creating forms that are not backed
  by any kind of data layer. Let's assume that we're submitting a
  form to the `:new` action in the `FooController`:

      <%= form_for @conn.params, Routes.foo_path(@conn, :new), fn f -> %>
        <%= text_input f, :contents %>
        <%= submit "Search" %>
      <% end %>

  Once the form is submitted, the form contents will be set directly
  as the parameters root, such as `conn.params["contents"]`. If you
  prefer, you can pass the `:as` option to configure them to be nested:

      <%= form_for @conn.params["search"] || %{}, Routes.foo_path(@conn, :new), [as: :search], fn f -> %>
        <%= text_input f, :contents %>
        <%= submit "Search" %>
      <% end %>

  In the example above, all form contents are now set inside `conn.params["search"]`
  thanks to the `[as: :search]` option.

  ## Nested inputs

  If your data layer supports embedding or nested associations,
  you can use `inputs_for` to attach nested data to the form.

  Imagine the following Ecto schemas:

      defmodule User do
        use Ecto.Schema

        schema "users" do
          field :name
          embeds_one :permalink, Permalink
        end

        def changeset(user \\ %User{}, params) do
          user
          |> Ecto.Changeset.cast(params, [:name])
          |> Ecto.Changeset.cast_embed(:permalink)
        end
      end

      defmodule Permalink do
        use Ecto.Schema

        embedded_schema do
          field :url
        end
      end

  In the form, you can now do this:

      <%= form_for @changeset, Routes.user_path(@conn, :create), fn f -> %>
        <%= text_input f, :name %>

        <%= inputs_for f, :permalink, fn fp -> %>
          <%= text_input fp, :url %>
        <% end %>
      <% end %>

  The default option can be given to populate the fields if none
  is given:

      <%= inputs_for f, :permalink, [default: %Permalink{title: "default"}], fn fp -> %>
        <%= text_input fp, :url %>
      <% end %>

  `inputs_for/4` can be used to work with single entities or
  collections. When working with collections, `:prepend` and
  `:append` can be used to add entries to the collection
  stored in the changeset.

  ## CSRF protection

  CSRF protection is a mechanism to ensure that the user who rendered
  the form is the one actually submitting it. This module generates a
  CSRF token by default. Your application should check this token on
  the server to prevent attackers from making requests on your server on
  behalf of other users. Phoenix checks this token by default.

  When posting a form with a host in its address, such as "//host.com/path"
  instead of only "/path", Phoenix will include the host signature in the
  token, and will only validate the token if the accessed host is the same as
  the host in the token. This is to avoid tokens from leaking to third-party
  applications. If this behaviour is problematic, you can generate a
  non-host-specific token with `Plug.CSRFProtection.get_csrf_token/0` and
  pass it to the form generator via the `:csrf_token` option.

  ## Options

    * `:as` - the server side parameter in which all params for this
      form will be collected (i.e. `as: :user_params` would mean all fields
      for this form will be accessed as `conn.params.user_params` server
      side). Automatically inflected when a changeset is given.

    * `:method` - the HTTP method. If the method is not "get" nor "post",
      an input tag with name `_method` is generated along-side the form tag.
      Defaults to "post".

    * `:multipart` - when true, sets enctype to "multipart/form-data".
      Required when uploading files.

    * `:csrf_token` - for "post" requests, the form tag will automatically
      include an input tag with name `_csrf_token`. When set to false, this
      is disabled.

    * `:errors` - use this to manually pass a keyword list of errors to the form
      (for example from `conn.assigns[:errors]`). This option is only used when a
      connection is used as the form source and it will make the errors available
      under `f.errors`.

    * `:id` - the ID of the form attribute. If an ID is given, all form inputs
      will also be prefixed by the given ID.

  All other options will be passed as HTML attributes, such as `class: "foo"`.
  """
  @spec form_for(Phoenix.HTML.FormData.t(), String.t(), (t -> Phoenix.HTML.unsafe())) ::
          Phoenix.HTML.safe()
  @spec form_for(Phoenix.HTML.FormData.t(), String.t(), Keyword.t(), (t -> Phoenix.HTML.unsafe())) ::
          Phoenix.HTML.safe()
  def form_for(form_data, action, options \\ [], fun) when is_function(fun, 1) do
    form = %{Phoenix.HTML.FormData.to_form(form_data, options) | action: action}
    html_escape([form_tag(action, form.options), fun.(form), raw("</form>")])
  end

  @doc false
  def inputs_for(form, field) when is_atom(field) or is_binary(field),
    do: inputs_for(form, field, [])

  @doc false
  def inputs_for(%{impl: impl} = form, field, options)
      when (is_atom(field) or is_binary(field)) and is_list(options) do
    IO.warn(
      "inputs_for/3 without an anonymous function is deprecated. " <>
        "If you are using HEEx templates, use the new Phoenix.Component.inputs_for/1 component"
    )

    options =
      form.options
      |> Keyword.take([:multipart])
      |> Keyword.merge(options)

    impl.to_form(form.source, form, field, options)
  end

  @doc """
  Generate a new form builder for the given parameter in form.

  See `form_for/4` for examples of using this function.

  ## Options

    * `:id` - the id to be used in the form, defaults to the
      concatenation of the given `field` to the parent form id

    * `:as` - the name to be used in the form, defaults to the
      concatenation of the given `field` to the parent form name

    * `:default` - the value to use if none is available

    * `:prepend` - the values to prepend when rendering. This only
      applies if the field value is a list and no parameters were
      sent through the form.

    * `:append` - the values to append when rendering. This only
      applies if the field value is a list and no parameters were
      sent through the form.

    * `:skip_hidden` - skip the automatic rendering of hidden
      fields to allow for more tight control over the generated
      markup. You can access `form.hidden` to generate them manually
      within the supplied callback.

  """
  @spec inputs_for(t, field, (t -> Phoenix.HTML.unsafe())) :: Phoenix.HTML.safe()
  @spec inputs_for(t, field, Keyword.t(), (t -> Phoenix.HTML.unsafe())) :: Phoenix.HTML.safe()
  def inputs_for(%{impl: impl} = form, field, options \\ [], fun)
      when is_atom(field) or is_binary(field) do
    {skip, options} = Keyword.pop(options, :skip_hidden, false)

    options =
      form.options
      |> Keyword.take([:multipart])
      |> Keyword.merge(options)

    forms = impl.to_form(form.source, form, field, options)

    html_escape(
      Enum.map(forms, fn form ->
        if skip do
          fun.(form)
        else
          [hidden_inputs_for(form), fun.(form)]
        end
      end)
    )
  end

  @mapping %{
    "url" => :url_input,
    "email" => :email_input,
    "search" => :search_input,
    "password" => :password_input
  }

  @doc """
  Gets the input type for a given field.

  If the underlying input type is a `:text_field`,
  a mapping could be given to further inflect
  the input type based solely on the field name.
  The default mapping is:

      %{"url"      => :url_input,
        "email"    => :email_input,
        "search"   => :search_input,
        "password" => :password_input}

  """
  @spec input_type(t, field) :: atom
  def input_type(%{impl: impl, source: source} = form, field, mapping \\ @mapping)
      when is_atom(field) or is_binary(field) do
    type = impl.input_type(source, form, field)

    if type == :text_input do
      field = field_to_string(field)

      Enum.find_value(mapping, type, fn {k, v} ->
        String.contains?(field, k) && v
      end)
    else
      type
    end
  end

  @doc """
  Generates a text input.

  The form should either be a `Phoenix.HTML.Form` emitted
  by `form_for` or an atom.

  All given options are forwarded to the underlying input,
  default values are provided for id, name and value if
  possible.

  ## Examples

      # Assuming form contains a User schema
      text_input(form, :name)
      #=> <input id="user_name" name="user[name]" type="text" value="">

      text_input(:user, :name)
      #=> <input id="user_name" name="user[name]" type="text" value="">

  """
  def text_input(form, field, opts \\ []) do
    generic_input(:text, form, field, opts)
  end

  @doc """
  Generates a hidden input.

  See `text_input/3` for example and docs.
  """
  def hidden_input(form, field, opts \\ []) do
    generic_input(:hidden, form, field, opts)
  end

  @doc """
  Generates hidden inputs for the given form inputs.

  See `inputs_for/2` and `inputs_for/3`.
  """
  @spec hidden_inputs_for(t) :: list(Phoenix.HTML.safe())
  def hidden_inputs_for(form) do
    Enum.flat_map(form.hidden, fn {k, v} ->
      hidden_inputs_for(form, k, v)
    end)
  end

  defp hidden_inputs_for(form, k, values) when is_list(values) do
    id = input_id(form, k)
    name = input_name(form, k)

    for {v, index} <- Enum.with_index(values) do
      hidden_input(form, k,
        id: id <> "_" <> Integer.to_string(index),
        name: name <> "[]",
        value: v
      )
    end
  end

  defp hidden_inputs_for(form, k, v) do
    [hidden_input(form, k, value: v)]
  end

  @doc """
  Generates an email input.

  See `text_input/3` for example and docs.
  """
  def email_input(form, field, opts \\ []) do
    generic_input(:email, form, field, opts)
  end

  @doc """
  Generates a number input.

  See `text_input/3` for example and docs.
  """
  def number_input(form, field, opts \\ []) do
    generic_input(:number, form, field, opts)
  end

  @doc """
  Generates a password input.

  For security reasons, the form data and parameter values
  are never re-used in `password_input/3`. Pass the value
  explicitly if you would like to set one.

  See `text_input/3` for example and docs.
  """
  def password_input(form, field, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:type, "password")
      |> Keyword.put_new(:id, input_id(form, field))
      |> Keyword.put_new(:name, input_name(form, field))

    tag(:input, opts)
  end

  @doc """
  Generates an url input.

  See `text_input/3` for example and docs.
  """
  def url_input(form, field, opts \\ []) do
    generic_input(:url, form, field, opts)
  end

  @doc """
  Generates a search input.

  See `text_input/3` for example and docs.
  """
  def search_input(form, field, opts \\ []) do
    generic_input(:search, form, field, opts)
  end

  @doc """
  Generates a telephone input.

  See `text_input/3` for example and docs.
  """
  def telephone_input(form, field, opts \\ []) do
    generic_input(:tel, form, field, opts)
  end

  @doc """
  Generates a color input.

  See `text_input/3` for example and docs.
  """
  def color_input(form, field, opts \\ []) do
    generic_input(:color, form, field, opts)
  end

  @doc """
  Generates a range input.

  See `text_input/3` for example and docs.
  """
  def range_input(form, field, opts \\ []) do
    generic_input(:range, form, field, opts)
  end

  @doc """
  Generates a date input.

  See `text_input/3` for example and docs.
  """
  def date_input(form, field, opts \\ []) do
    generic_input(:date, form, field, opts)
  end

  @doc """
  Generates a datetime-local input.

  See `text_input/3` for example and docs.
  """
  def datetime_local_input(form, field, opts \\ []) do
    value = Keyword.get(opts, :value, input_value(form, field))
    opts = Keyword.put(opts, :value, normalize_value("datetime-local", value))

    generic_input(:"datetime-local", form, field, opts)
  end

  @doc """
  Generates a time input.

  ## Options

    * `:precision` - Allowed values: `:minute`, `:second`, `:millisecond`.
      Defaults to `:minute`.

  All other options are forwarded. See `text_input/3` for example and docs.

  ## Examples

      time_input form, :time
      #=> <input id="form_time" name="form[time]" type="time" value="23:00">

      time_input form, :time, precision: :second
      #=> <input id="form_time" name="form[time]" type="time" value="23:00:00">

      time_input form, :time, precision: :millisecond
      #=> <input id="form_time" name="form[time]" type="time" value="23:00:00.000">
  """
  def time_input(form, field, opts \\ []) do
    {precision, opts} = Keyword.pop(opts, :precision, :minute)
    value = opts[:value] || input_value(form, field)
    opts = Keyword.put(opts, :value, truncate_time(value, precision))

    generic_input(:time, form, field, opts)
  end

  defp truncate_time(%Time{} = time, :minute) do
    time
    |> Time.to_string()
    |> String.slice(0, 5)
  end

  defp truncate_time(%Time{} = time, precision) do
    time
    |> Time.truncate(precision)
    |> Time.to_string()
  end

  defp truncate_time(value, _), do: value

  defp generic_input(type, form, field, opts)
       when is_list(opts) and (is_atom(field) or is_binary(field)) do
    opts =
      opts
      |> Keyword.put_new(:type, type)
      |> Keyword.put_new(:id, input_id(form, field))
      |> Keyword.put_new(:name, input_name(form, field))
      |> Keyword.put_new(:value, input_value(form, field))
      |> Keyword.update!(:value, &maybe_html_escape/1)

    tag(:input, opts)
  end

  defp maybe_html_escape(nil), do: nil
  defp maybe_html_escape(value), do: html_escape(value)

  @doc """
  Generates a textarea input.

  All given options are forwarded to the underlying input,
  default values are provided for id, name and textarea
  content if possible.

  ## Examples

      # Assuming form contains a User schema
      textarea(form, :description)
      #=> <textarea id="user_description" name="user[description]"></textarea>

  ## New lines

  Notice the generated textarea includes a new line after
  the opening tag. This is because the HTML spec says new
  lines after tags must be ignored, and all major browser
  implementations do that.

  Therefore, in order to avoid new lines provided by the user
  from being ignored when the form is resubmitted, we
  automatically add a new line before the text area
  value.
  """
  def textarea(form, field, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:id, input_id(form, field))
      |> Keyword.put_new(:name, input_name(form, field))

    {value, opts} = Keyword.pop(opts, :value, input_value(form, field))
    content_tag(:textarea, normalize_value("textarea", value), opts)
  end

  @doc """
  Generates a file input.

  It requires the given form to be configured with `multipart: true`
  when invoking `form_for/4`, otherwise it fails with `ArgumentError`.

  See `text_input/3` for example and docs.
  """
  def file_input(form, field, opts \\ []) do
    if match?(%Form{}, form) and !form.options[:multipart] do
      raise ArgumentError,
            "file_input/3 requires the enclosing form_for/4 " <>
              "to be configured with multipart: true"
    end

    opts =
      opts
      |> Keyword.put_new(:type, :file)
      |> Keyword.put_new(:id, input_id(form, field))
      |> Keyword.put_new(:name, input_name(form, field))

    opts =
      if opts[:multiple] do
        Keyword.update!(opts, :name, &"#{&1}[]")
      else
        opts
      end

    tag(:input, opts)
  end

  @doc """
  Generates a submit button to send the form.

  ## Examples

      submit do: "Submit"
      #=> <button type="submit">Submit</button>

  """
  def submit([do: _] = block_option), do: submit([], block_option)

  @doc """
  Generates a submit button to send the form.

  All options are forwarded to the underlying button tag.
  When called with a `do:` block, the button tag options
  come first.

  ## Examples

      submit "Submit"
      #=> <button type="submit">Submit</button>

      submit "Submit", class: "btn"
      #=> <button class="btn" type="submit">Submit</button>

      submit [class: "btn"], do: "Submit"
      #=> <button class="btn" type="submit">Submit</button>

  """
  def submit(value, opts \\ [])

  def submit(opts, [do: _] = block_option) do
    opts = Keyword.put_new(opts, :type, "submit")

    content_tag(:button, opts, block_option)
  end

  def submit(value, opts) do
    opts = Keyword.put_new(opts, :type, "submit")

    content_tag(:button, value, opts)
  end

  @doc """
  Generates a reset input to reset all the form fields to
  their original state.

  All options are forwarded to the underlying input tag.

  ## Examples

      reset "Reset"
      #=> <input type="reset" value="Reset">

      reset "Reset", class: "btn"
      #=> <input type="reset" value="Reset" class="btn">

  """
  def reset(value, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:type, "reset")
      |> Keyword.put_new(:value, value)

    tag(:input, opts)
  end

  @doc """
  Generates a radio button.

  Invoke this function for each possible value you want
  to be sent to the server.

  ## Examples

      # Assuming form contains a User schema
      radio_button(form, :role, "admin")
      #=> <input id="user_role_admin" name="user[role]" type="radio" value="admin">

  ## Options

  All options are simply forwarded to the underlying HTML tag.
  """
  def radio_button(form, field, value, opts \\ []) do
    escaped_value = html_escape(value)

    opts =
      opts
      |> Keyword.put_new(:type, "radio")
      |> Keyword.put_new(:id, input_id(form, field, escaped_value))
      |> Keyword.put_new(:name, input_name(form, field))

    opts =
      if escaped_value == html_escape(input_value(form, field)) do
        Keyword.put_new(opts, :checked, true)
      else
        opts
      end

    tag(:input, [value: escaped_value] ++ opts)
  end

  @doc """
  Generates a checkbox.

  This function is useful for sending boolean values to the server.

  ## Examples

      # Assuming form contains a User schema
      checkbox(form, :famous)
      #=> <input name="user[famous]" type="hidden" value="false">
      #=> <input checked="checked" id="user_famous" name="user[famous]" type="checkbox" value="true">

  ## Options

    * `:checked_value` - the value to be sent when the checkbox is checked.
      Defaults to "true"

    * `:hidden_input` - controls if this function will generate a hidden input
      to submit the unchecked value or not. Defaults to "true"

    * `:unchecked_value` - the value to be sent when the checkbox is unchecked,
      Defaults to "false"

    * `:value` - the value used to check if a checkbox is checked or unchecked.
      The default value is extracted from the form data if available

  All other options are forwarded to the underlying HTML tag.

  ## Hidden fields

  Because an unchecked checkbox is not sent to the server, Phoenix
  automatically generates a hidden field with the unchecked_value
  *before* the checkbox field to ensure the `unchecked_value` is sent
  when the checkbox is not marked. Set `hidden_input` to false If you
  don't want to send values from unchecked checkbox to the server.
  """
  def checkbox(form, field, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:type, "checkbox")
      |> Keyword.put_new(:name, input_name(form, field))

    {value, opts} = Keyword.pop(opts, :value, input_value(form, field))
    {checked_value, opts} = Keyword.pop(opts, :checked_value, true)
    {unchecked_value, opts} = Keyword.pop(opts, :unchecked_value, false)
    {hidden_input, opts} = Keyword.pop(opts, :hidden_input, true)

    # We html escape all values to be sure we are comparing
    # apples to apples. After all, we may have true in the data
    # but "true" in the params and both need to match.
    checked_value = html_escape(checked_value)
    unchecked_value = html_escape(unchecked_value)

    opts =
      opts
      |> Keyword.put_new_lazy(:checked, fn ->
        value = html_escape(value)
        value == checked_value
      end)
      |> Keyword.put_new_lazy(:id, fn ->
        if String.ends_with?(opts[:name], "[]"),
          do: input_id(form, field, checked_value),
          else: input_id(form, field)
      end)

    if hidden_input do
      hidden_opts = [type: "hidden", value: unchecked_value]

      html_escape([
        tag(:input, hidden_opts ++ Keyword.take(opts, [:name, :disabled, :form])),
        tag(:input, [value: checked_value] ++ opts)
      ])
    else
      html_escape([
        tag(:input, [value: checked_value] ++ opts)
      ])
    end
  end

  @doc """
  Generates a select tag with the given `options`.

  `options` are expected to be an enumerable which will be used to
  generate each respective `option`. The enumerable may have:

    * keyword lists - each keyword list is expected to have the keys
      `:key` and `:value`. Additional keys such as `:disabled` may
      be given to customize the option.

    * two-item tuples - where the first element is an atom, string or
      integer to be used as the option label and the second element is
      an atom, string or integer to be used as the option value

    * atom, string or integer - which will be used as both label and value
      for the generated select

  ## Optgroups

  If `options` is map or keyword list where the first element is a string,
  atom or integer and the second element is a list or a map, it is assumed
  the key will be wrapped in an `<optgroup>` and the value will be used to
  generate `<options>` nested under the group.

  ## Examples

      # Assuming form contains a User schema
      select(form, :age, 0..120)
      #=> <select id="user_age" name="user[age]">
      #=>   <option value="0">0</option>
      #=>   ...
      #=>   <option value="120">120</option>
      #=> </select>

      select(form, :role, ["Admin": "admin", "User": "user"])
      #=> <select id="user_role" name="user[role]">
      #=>   <option value="admin">Admin</option>
      #=>   <option value="user">User</option>
      #=> </select>

      select(form, :role, [[key: "Admin", value: "admin", disabled: true],
                           [key: "User", value: "user"]])
      #=> <select id="user_role" name="user[role]">
      #=>   <option value="admin" disabled="disabled">Admin</option>
      #=>   <option value="user">User</option>
      #=> </select>

  You can also pass a prompt:

      select(form, :role, ["Admin": "admin", "User": "user"], prompt: "Choose your role")
      #=> <select id="user_role" name="user[role]">
      #=>   <option value="">Choose your role</option>
      #=>   <option value="admin">Admin</option>
      #=>   <option value="user">User</option>
      #=> </select>

  And customize the prompt like any other entry:

      select(form, :role, ["Admin": "admin", "User": "user"], prompt: [key: "Choose your role", disabled: true])
      #=> <select id="user_role" name="user[role]">
      #=>   <option value="" disabled="">Choose your role</option>
      #=>   <option value="admin">Admin</option>
      #=>   <option value="user">User</option>
      #=> </select>

  If you want to select an option that comes from the database,
  such as a manager for a given project, you may write:

      select(form, :manager_id, Enum.map(@managers, &{&1.name, &1.id}))
      #=> <select id="manager_id" name="project[manager_id]">
      #=>   <option value="1">Mary Jane</option>
      #=>   <option value="2">John Doe</option>
      #=> </select>

  Finally, if the values are a list or a map, we use the keys for
  grouping:

      select(form, :country, ["Europe": ["UK", "Sweden", "France"]], ...)
      #=> <select id="user_country" name="user[country]">
      #=>   <optgroup label="Europe">
      #=>     <option>UK</option>
      #=>     <option>Sweden</option>
      #=>     <option>France</option>
      #=>   </optgroup>
      #=>   ...
      #=> </select>

  ## Options

    * `:prompt` - an option to include at the top of the options. It may be
      a string or a keyword list of attributes and the `:key`

    * `:selected` - the default value to use when none was sent as parameter

  Be aware that a `:multiple` option will not generate a correctly
  functioning multiple select element. Use `multiple_select/4` instead.

  All other options are forwarded to the underlying HTML tag.
  """
  def select(form, field, options, opts \\ []) when is_atom(field) or is_binary(field) do
    {selected, opts} = selected(form, field, opts)
    options_html = options_for_select(options, selected)

    {options_html, opts} =
      case Keyword.pop(opts, :prompt) do
        {nil, opts} -> {options_html, opts}
        {prompt, opts} -> {[prompt_option(prompt) | options_html], opts}
      end

    opts =
      opts
      |> Keyword.put_new(:id, input_id(form, field))
      |> Keyword.put_new(:name, input_name(form, field))

    content_tag(:select, options_html, opts)
  end

  defp prompt_option(prompt) when is_list(prompt) do
    {prompt_key, prompt_opts} = Keyword.pop(prompt, :key)

    prompt_key ||
      raise ArgumentError,
            "expected :key key when building a prompt select option with a keyword list: " <>
              inspect(prompt)

    prompt_option(prompt_key, prompt_opts)
  end

  defp prompt_option(key) when is_binary(key), do: prompt_option(key, [])

  defp prompt_option(key, opts) when is_list(opts) do
    content_tag(:option, key, Keyword.put_new(opts, :value, ""))
  end

  @doc """
  Generates a select tag with the given `options`.

  Values are expected to be an Enumerable containing two-item tuples
  (like maps and keyword lists) or any Enumerable where the element
  will be used both as key and value for the generated select.

  ## Examples

      # Assuming form contains a User schema
      multiple_select(form, :roles, ["Admin": 1, "Power User": 2])
      #=> <select id="user_roles" name="user[roles][]">
      #=>   <option value="1">Admin</option>
      #=>   <option value="2">Power User</option>
      #=> </select>

      multiple_select(form, :roles, ["Admin": 1, "Power User": 2], selected: [1])
      #=> <select id="user_roles" name="user[roles][]">
      #=>   <option value="1" selected="selected">Admin</option>
      #=>   <option value="2">Power User</option>
      #=> </select>

  When working with structs, associations, and embeds, you will need to tell
  Phoenix how to extract the value out of the collection. For example,
  imagine `user.roles` is a list of `%Role{}` structs. You must call it as:

      multiple_select(form, :roles, ["Admin": 1, "Power User": 2],
                      selected: Enum.map(@user.roles, &(&1.id))

  The `:selected` option will mark the given IDs as selected unless the form
  is being resubmitted. When resubmitted, it uses the form params as values.

  When used with Ecto, you will typically do a query to retrieve the IDs from
  the database:

      from r in Role, where: r.id in ^(params["roles"] || [])

  And then use `Ecto.Changeset.put_assoc/2` to insert the new roles into the user.

  ## Options

    * `:selected` - the default options to be marked as selected. The values
       on this list are ignored in case ids have been set as parameters.

  All other options are forwarded to the underlying HTML tag.
  """
  def multiple_select(form, field, options, opts \\ []) do
    {selected, opts} = selected(form, field, opts)

    opts =
      opts
      |> Keyword.put_new(:id, input_id(form, field))
      |> Keyword.put_new(:name, input_name(form, field) <> "[]")
      |> Keyword.put_new(:multiple, "")

    content_tag(:select, options_for_select(options, selected), opts)
  end

  defp selected(form, field, opts) do
    {value, opts} = Keyword.pop(opts, :value)
    {selected, opts} = Keyword.pop(opts, :selected)

    if value != nil do
      {value, opts}
    else
      param = field_to_string(field)

      case form do
        %{params: %{^param => sent}} ->
          {sent, opts}

        _ ->
          {selected || input_value(form, field), opts}
      end
    end
  end

  ## Datetime

  @doc ~S'''
  Generates select tags for datetime.

  Warning: This functionality is best provided by browsers nowadays.
  Consider using `datetime_local_input/3` instead.

  ## Examples

      # Assuming form contains a User schema
      datetime_select form, :born_at
      #=> <select id="user_born_at_year" name="user[born_at][year]">...</select> /
      #=> <select id="user_born_at_month" name="user[born_at][month]">...</select> /
      #=> <select id="user_born_at_day" name="user[born_at][day]">...</select> —
      #=> <select id="user_born_at_hour" name="user[born_at][hour]">...</select> :
      #=> <select id="user_born_at_min" name="user[born_at][minute]">...</select>

  If you want to include the seconds field (hidden by default), pass `second: []`:

      # Assuming form contains a User schema
      datetime_select form, :born_at, second: []

  If you want to configure the years range:

      # Assuming form contains a User schema
      datetime_select form, :born_at, year: [options: 1900..2100]

  You are also able to configure `:month`, `:day`, `:hour`, `:minute` and
  `:second`. All options given to those keys will be forwarded to the
  underlying select. See `select/4` for more information.

  For example, if you are using Phoenix with Gettext and you want to localize
  the list of months, you can pass `:options` to the `:month` key:

      # Assuming form contains a User schema
      datetime_select form, :born_at, month: [
        options: [
          {gettext("January"), "1"},
          {gettext("February"), "2"},
          {gettext("March"), "3"},
          {gettext("April"), "4"},
          {gettext("May"), "5"},
          {gettext("June"), "6"},
          {gettext("July"), "7"},
          {gettext("August"), "8"},
          {gettext("September"), "9"},
          {gettext("October"), "10"},
          {gettext("November"), "11"},
          {gettext("December"), "12"},
        ]
      ]

  You may even provide your own `localized_datetime_select/3` built on top of
  `datetime_select/3`:

      defp localized_datetime_select(form, field, opts \\ []) do
        opts =
          Keyword.put(opts, :month, options: [
            {gettext("January"), "1"},
            {gettext("February"), "2"},
            {gettext("March"), "3"},
            {gettext("April"), "4"},
            {gettext("May"), "5"},
            {gettext("June"), "6"},
            {gettext("July"), "7"},
            {gettext("August"), "8"},
            {gettext("September"), "9"},
            {gettext("October"), "10"},
            {gettext("November"), "11"},
            {gettext("December"), "12"},
          ])

        datetime_select(form, field, opts)
      end

  ## Options

    * `:value` - the value used to select a given option.
      The default value is extracted from the form data if available.

    * `:default` - the default value to use when none was given in
      `:value` and none is available in the form data

    * `:year`, `:month`, `:day`, `:hour`, `:minute`, `:second` - options passed
      to the underlying select. See `select/4` for more information.
      The available values can be given in `:options`.

    * `:builder` - specify how the select can be build. It must be a function
      that receives a builder that should be invoked with the select name
      and a set of options. See builder below for more information.

  ## Builder

  The generated datetime_select can be customized at will by providing a
  builder option. Here is an example from EEx:

      <%= datetime_select form, :born_at, builder: fn b -> %>
        Date: <%= b.(:day, []) %> / <%= b.(:month, []) %> / <%= b.(:year, []) %>
        Time: <%= b.(:hour, []) %> : <%= b.(:minute, []) %>
      <% end %>

  Although we have passed empty lists as options (they are required), you
  could pass any option there and it would be given to the underlying select
  input.

  In practice, we recommend you to create your own helper with your default
  builder:

      def my_datetime_select(form, field, opts \\ []) do
        builder = fn b ->
          assigns = %{b: b}

          ~H"""
          Date: <%= @b.(:day, []) %> / <%= @b.(:month, []) %> / <%= @b.(:year, []) %>
          Time: <%= @b.(:hour, []) %> : <%= @b.(:minute, []) %>
          """
        end

        datetime_select(form, field, [builder: builder] ++ opts)
      end

  Then you are able to use your own datetime_select throughout your whole
  application.

  ## Supported date values

  The following values are supported as date:

    * a map containing the `year`, `month` and `day` keys (either as strings or atoms)
    * a tuple with three elements: `{year, month, day}`
    * a string in ISO 8601 format
    * `nil`

  ## Supported time values

  The following values are supported as time:

    * a map containing the `hour` and `minute` keys and an optional `second` key (either as strings or atoms)
    * a tuple with three elements: `{hour, min, sec}`
    * a tuple with four elements: `{hour, min, sec, usec}`
    * `nil`

  '''
  def datetime_select(form, field, opts \\ []) do
    value = Keyword.get(opts, :value, input_value(form, field) || Keyword.get(opts, :default))

    builder =
      Keyword.get(opts, :builder) ||
        fn b ->
          date = date_builder(b, opts)
          time = time_builder(b, opts)
          html_escape([date, raw(" &mdash; "), time])
        end

    builder.(datetime_builder(form, field, date_value(value), time_value(value), opts))
  end

  @doc """
  Generates select tags for date.

  Warning: This functionality is best provided by browsers nowadays.
  Consider using `date_input/3` instead.

  Check `datetime_select/3` for more information on options and supported values.
  """
  def date_select(form, field, opts \\ []) do
    value = Keyword.get(opts, :value, input_value(form, field) || Keyword.get(opts, :default))
    builder = Keyword.get(opts, :builder) || (&date_builder(&1, opts))
    builder.(datetime_builder(form, field, date_value(value), nil, opts))
  end

  defp date_builder(b, _opts) do
    html_escape([b.(:year, []), raw(" / "), b.(:month, []), raw(" / "), b.(:day, [])])
  end

  defp date_value(%{"year" => year, "month" => month, "day" => day}),
    do: %{year: year, month: month, day: day}

  defp date_value(%{year: year, month: month, day: day}),
    do: %{year: year, month: month, day: day}

  defp date_value({{year, month, day}, _}), do: %{year: year, month: month, day: day}
  defp date_value({year, month, day}), do: %{year: year, month: month, day: day}

  defp date_value(nil), do: %{year: nil, month: nil, day: nil}

  defp date_value(string) when is_binary(string) do
    string
    |> Date.from_iso8601!()
    |> date_value
  end

  defp date_value(other), do: raise(ArgumentError, "unrecognized date #{inspect(other)}")

  @doc """
  Generates select tags for time.

  Warning: This functionality is best provided by browsers nowadays.
  Consider using `time_input/3` instead.

  Check `datetime_select/3` for more information on options and supported values.
  """
  def time_select(form, field, opts \\ []) do
    value = Keyword.get(opts, :value, input_value(form, field) || Keyword.get(opts, :default))
    builder = Keyword.get(opts, :builder) || (&time_builder(&1, opts))
    builder.(datetime_builder(form, field, nil, time_value(value), opts))
  end

  defp time_builder(b, opts) do
    time = html_escape([b.(:hour, []), raw(" : "), b.(:minute, [])])

    if Keyword.get(opts, :second) do
      html_escape([time, raw(" : "), b.(:second, [])])
    else
      time
    end
  end

  defp time_value(%{"hour" => hour, "minute" => min} = map),
    do: %{hour: hour, minute: min, second: Map.get(map, "second", 0)}

  defp time_value(%{hour: hour, minute: min} = map),
    do: %{hour: hour, minute: min, second: Map.get(map, :second, 0)}

  defp time_value({_, {hour, min, sec}}),
    do: %{hour: hour, minute: min, second: sec}

  defp time_value({hour, min, sec}),
    do: %{hour: hour, minute: min, second: sec}

  defp time_value(nil), do: %{hour: nil, minute: nil, second: nil}

  defp time_value(string) when is_binary(string) do
    string
    |> Time.from_iso8601!()
    |> time_value
  end

  defp time_value(other), do: raise(ArgumentError, "unrecognized time #{inspect(other)}")

  @months [
    {"January", "1"},
    {"February", "2"},
    {"March", "3"},
    {"April", "4"},
    {"May", "5"},
    {"June", "6"},
    {"July", "7"},
    {"August", "8"},
    {"September", "9"},
    {"October", "10"},
    {"November", "11"},
    {"December", "12"}
  ]

  map =
    &Enum.map(&1, fn i ->
      pre = if i < 10, do: "0"
      {"#{pre}#{i}", i}
    end)

  @days map.(1..31)
  @hours map.(0..23)
  @minsec map.(0..59)

  defp datetime_builder(form, field, date, time, parent) do
    id = Keyword.get(parent, :id, input_id(form, field))
    name = Keyword.get(parent, :name, input_name(form, field))

    fn
      :year, opts when date != nil ->
        {year, _, _} = :erlang.date()

        {value, opts} =
          datetime_options(:year, (year - 5)..(year + 5), id, name, parent, date, opts)

        select(:datetime, :year, value, opts)

      :month, opts when date != nil ->
        {value, opts} = datetime_options(:month, @months, id, name, parent, date, opts)
        select(:datetime, :month, value, opts)

      :day, opts when date != nil ->
        {value, opts} = datetime_options(:day, @days, id, name, parent, date, opts)
        select(:datetime, :day, value, opts)

      :hour, opts when time != nil ->
        {value, opts} = datetime_options(:hour, @hours, id, name, parent, time, opts)
        select(:datetime, :hour, value, opts)

      :minute, opts when time != nil ->
        {value, opts} = datetime_options(:minute, @minsec, id, name, parent, time, opts)
        select(:datetime, :minute, value, opts)

      :second, opts when time != nil ->
        {value, opts} = datetime_options(:second, @minsec, id, name, parent, time, opts)
        select(:datetime, :second, value, opts)
    end
  end

  defp datetime_options(type, values, id, name, parent, datetime, opts) do
    opts = Keyword.merge(Keyword.get(parent, type, []), opts)
    suff = Atom.to_string(type)

    {value, opts} = Keyword.pop(opts, :options, values)

    {value,
     opts
     |> Keyword.put_new(:id, id <> "_" <> suff)
     |> Keyword.put_new(:name, name <> "[" <> suff <> "]")
     |> Keyword.put_new(:value, Map.get(datetime, type))}
  end

  @doc """
  Generates a label tag.

  Useful when wrapping another input inside a label.

  ## Examples

      label do
        radio_button :user, :choice, "Choice"
      end
      #=> <label>...</label>

      label class: "control-label" do
        radio_button :user, :choice, "Choice"
      end
      #=> <label class="control-label">...</label>

  """
  def label(do_block)

  def label(do: block) do
    content_tag(:label, block, [])
  end

  def label(opts, do: block) when is_list(opts) do
    content_tag(:label, block, opts)
  end

  @doc """
  Generates a label tag for the given field.

  The form should either be a `Phoenix.HTML.Form` emitted
  by `form_for` or an atom.

  All given options are forwarded to the underlying tag.
  A default value is provided for `for` attribute but can
  be overridden if you pass a value to the `for` option.
  Text content would be inferred from `field` if not specified
  as either a function argument or string value in a block.

  To wrap a label around an input, see `label/1`.

  ## Examples

      # Assuming form contains a User schema
      label(form, :name, "Name")
      #=> <label for="user_name">Name</label>

      label(:user, :email, "Email")
      #=> <label for="user_email">Email</label>

      label(:user, :email)
      #=> <label for="user_email">Email</label>

      label(:user, :email, class: "control-label")
      #=> <label for="user_email" class="control-label">Email</label>

      label :user, :email do
        "E-mail Address"
      end
      #=> <label for="user_email">E-mail Address</label>

      label :user, :email, "E-mail Address", class: "control-label"
      #=> <label class="control-label" for="user_email">E-mail Address</label>

      label :user, :email, class: "control-label" do
        "E-mail Address"
      end
      #=> <label class="control-label" for="user_email">E-mail Address</label>

  """
  def label(form, field) when is_atom(field) or is_binary(field) do
    label(form, field, humanize(field), [])
  end

  @doc """
  See `label/2`.
  """
  def label(form, field, text_or_do_block_or_attributes)

  def label(form, field, do: block) do
    label(form, field, [], do: block)
  end

  def label(form, field, opts) when is_list(opts) do
    label(form, field, humanize(field), opts)
  end

  def label(form, field, text) do
    label(form, field, text, [])
  end

  @doc """
  See `label/2`.
  """
  def label(form, field, text, do_block_or_attributes)

  def label(form, field, opts, do: block) when is_list(opts) do
    opts = Keyword.put_new(opts, :for, input_id(form, field))
    content_tag(:label, block, opts)
  end

  def label(form, field, text, opts) when is_list(opts) do
    opts = Keyword.put_new(opts, :for, input_id(form, field))
    content_tag(:label, text, opts)
  end

  # Normalize field name to string version
  defp field_to_string(field) when is_atom(field), do: Atom.to_string(field)
  defp field_to_string(field) when is_binary(field), do: field

  # Helper for getting field errors, handling string fields
  defp field_errors(errors, field)
       when is_list(errors) and (is_atom(field) or is_binary(field)) do
    for {^field, error} <- errors, do: error
  end
end

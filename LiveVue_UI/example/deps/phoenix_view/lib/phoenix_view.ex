defmodule Phoenix.View do
  @moduledoc """
  A module for generating `render/2` functions from templates on disk.

  With design patterns introduced by `Phoenix.LiveView`, this module has fallen
  out of fashion in favor of `Phoenix.Component`, even in non LiveView
  applications. See the "Replaced by `Phoenix.Component`" section below.

  ## Examples

  In Phoenix v1.6 and earlier, new Phoenix apps defined a blueprint for views
  at `lib/your_app_web.ex`. It generally looked like this:

      defmodule YourAppWeb do
        # ...

        def view do
          quote do
            use Phoenix.View, root: "lib/your_app_web/templates", namespace: YourAppWeb

            # Import convenience functions from controllers
            import Phoenix.Controller,
              only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

            # Use all HTML functionality (forms, tags, etc)
            use Phoenix.HTML

            import YourAppWeb.ErrorHelpers
            import YourAppWeb.Gettext
          end
        end

        # ...
      end

  Then you could use the definition above to define any view in your application:

      defmodule YourAppWeb.UserView do
        use YourAppWeb, :view
      end

  Because we defined the template root to be "lib/your_app_web/templates",
  `Phoenix.View` will automatically load all templates at "your_app_web/templates/user"
  and include them in the `YourApp.UserView`. For example, imagine we have the
  template:

      # your_app_web/templates/user/index.html.heex
      Hello <%= @name %>

  The `.heex` extension maps to a template engine which tells Phoenix how
  to compile the code in the file into Elixir source code. After it is
  compiled, the template can be rendered as:

      Phoenix.View.render_to_string(YourApp.UserView, "index.html", name: "John Doe")
      #=> "Hello John Doe"

  ## Rendering and formats

  `Phoenix.View` renders templates.

  A template has a name, which also contains a format. For example,
  in the previous section we have rendered the "index.html" template:

      Phoenix.View.render_to_string(YourApp.UserView, "index.html", name: "John Doe")
      #=> "Hello John Doe"

  While we got a string at the end, that's not actually what our templates
  render. Let's take a deeper look:

      Phoenix.View.render(YourApp.UserView, "index.html", name: "John Doe")
      #=> ...

  This inner representation allows us to separate how templates render and
  how they are encoded. For example, if you want to render JSON data, we
  could do so by adding a "show.json" entry to `render/2` in our view:

      defmodule YourAppWeb.UserView do
        use YourAppWeb, :view

        def render("show.json", %{user: user}) do
          %{name: user.name, address: user.address}
        end
      end

  Notice that in order to render JSON data, we don't need to explicitly
  return a JSON string! Instead, we just return data that is encodable to
  JSON. Now, when we call:

      Phoenix.View.render_to_string(YourApp.UserView, "user.json", user: %User{...})

  Because the template has the `.json` extension, Phoenix knows how to
  encode the map returned for the "user.json" template into an actual
  JSON payload to be sent over the wire.

  Phoenix ships with some template engines and format encoders, which
  can be further configured in the Phoenix application. You can read
  more about format encoders in `Phoenix.Template` documentation.

  ## Replaced by `Phoenix.Component`

  In `Phoenix.LiveView`, `Phoenix.View` was replaced by `Phoenix.Component`.
  With Phoenix v1.7+ we can also use `Phoenix.Component` to render traditional
  templates as functional components, using the `embed_templates` function.

  For example, in Phoenix v1.7+, the `YourAppWeb.UserView` above would be
  written as:

      defmodule YourAppWeb.UserHTML do
        use YourAppWeb, :html

        embed_templates "users/*"
      end

  The benefit of `Phoenix.Component` is that it unifies the rendering of
  traditional request/response life cycles with the composable component
  model provided by LiveView.

  The table below summarizes how the defaults changed from Phoenix v1.6 to v1.7:

  | Feature                          | Phoenix v1.6                            | Phoenix v1.7                                  |
  | -------------------------------- | --------------------------------------- | --------------------------------------------- |
  | `MyController.action/2` renders  | `MyView.render("action.html", assigns)` | `MyHTML.action(assigns)`                      |
  | Define views at                  | `lib/my_app/views/my_view.ex`           | `lib/my_app/controllers/my_html.ex`           |
  | At the top of your views         | `use MyAppWeb, :view`                   | `use MyAppWeb, :html`                         |
  | Default template language        | `EEx` (`.eex` extension)                | `HEEx` (`.heex` extension)                    |
  | To embed templates from disk     | `use Phoenix.View`                      | `use Phoenix.Component` (+ `embed_templates`) |
  | HTML helpers (forms, links, etc) | `use Phoenix.HTML`                      | `use Phoenix.Component`                       |

  However, note Phoenix v1.7 is backwards compatible with v1.6 if you want to
  keep with the old style. The functionality in this module will be maintained
  in the long term though for those who cannot or prefer not to migrate.

  ### Migrating to Phoenix.Component

  Migrating your current views to components be done in a few steps. You should
  also be able to migrate one view at a time.

  > It may be helpful to generate a new project using Phoenix v1.7+ to compare
  > code samples during this process.

  The first step is to define `def html` in your `lib/my_app_web.ex` module.
  This function is similar to `def view`, but it replaces `use Phoenix.View`
  by `use Phoenix.Component` (requires LiveView 0.18.3 or later). We also
  recomend to add `import Phoenix.View` inside `def html` while migrating.

  Then, for each view, you must follow these steps (we will assume the
  current view is called `MyAppWeb.MyView`):

    1. Replace `render_existing/3` calls by `function_exported?/3` checks,
       according to the `render_existing` documentation.

    2. Replace `use MyApp, :view` by `use MyApp, :html` and invoke
       `embed_templates "../templates/my/*"`. Alternatively, you can move
       both the HTML file and its templates to the `controllers` directory,
       to align with Phoenix v1.7 conventions.

    3. Your templates may now break if they are calling `render/2`.
       You can address this by replacing `render/2` with a function
       component. For instance, `render("_form.html", changeset: @changeset, user: @user)`
       must now be called as `<._form changeset={@changeset} user={@user} />`.
       If passing all assigns, `render("_form.html", assigns)` becomes
       `<%= _form(assigns) %>`

    4. Your templates may now break if they are calling `render_layout/4`.
       You can address this by converting the layout into a function component
       that receives its contents as a slot. See `render_layout/4` docs

  Now you are using components! Once you convert all views, you should
  be able to remove `Phoenix.View` as a dependency from your project.

  Remove `def view` and also remove the `import Phoenix.View` from
  `def html` in your `lib/my_app_web.ex` module. When doing so,
  compilation may fail if you are using certain functions:

    * Replace `render/3` with a function component. For instance,
      `render(OtherView, "_form.html", changeset: @changeset, user: @user)`
      can now be called as `<OtherView.form changeset={@changeset} user={@user} />`.
      If passing all assigns, `render(OtherView, "_form.html", assigns)`
      becomes `<%= OtherView._form(assigns) %>`.

    * If you are using `Phoenix.View` for APIs, you can remove `Phoenix.View`
      altogether. Instead of `def render("index.html", assigns)`, use `def users(assigns)`.
      Instead of `def render("show.html", assigns)`, do `def user(assigns)`.
      Instead `render_one`/`render_many`, call the `users/1` and `user/1` functions
      directly.

  """

  alias Phoenix.Template

  @doc """
  When used, defines the current module as a main view module.

  ## Options

    * `:root` - the template root to find templates
    * `:path` - the optional path to search for templates within the `:root`.
      Defaults to the underscored view module name. A blank string may
      be provided to use the `:root` path directly as the template lookup path
    * `:namespace` - the namespace to consider when calculating view paths
    * `:pattern` - the wildcard pattern to apply to the root
      when finding templates. Default `"*"`

  The `:root` option is required while the `:namespace` defaults to the
  first nesting in the module name. For instance, both `MyApp.UserView`
  and `MyApp.Admin.UserView` have namespace `MyApp`.

  The `:namespace` and `:path` options are used to calculate template
  lookup paths. For example, if you are in `MyApp.UserView` and the
  namespace is `MyApp`, templates are expected at `Path.join(root, "user")`.
  On the other hand, if the view is `MyApp.Admin.UserView`,
  the path will be `Path.join(root, "admin/user")` and so on. For
  explicit root path locations, the `:path` option can be provided instead.
  The `:root` and `:path` are joined to form the final lookup path.
  A blank string may be provided to use the `:root` path directly as the
  template lookup path.

  Setting the namespace to `MyApp.Admin` in the second example will force
  the template to also be looked up at `Path.join(root, "user")`.
  """
  defmacro __using__(opts) do
    opts =
      if Macro.quoted_literal?(opts) do
        Macro.prewalk(opts, &expand_alias(&1, __CALLER__))
      else
        opts
      end

    quote do
      # Register setup first, because its before_compile
      # needs to run before Phoenix.Template callback.
      Phoenix.View.__setup__(__MODULE__, unquote(opts))

      use Phoenix.Template
      import Phoenix.View

      @doc """
      Callback invoked when no template is found.
      By default it raises but can be customized
      to render a particular template.
      """
      @spec template_not_found(binary, map) :: no_return
      def template_not_found(template, assigns) do
        Phoenix.View.__not_found__!(__MODULE__, template, assigns)
      end

      defoverridable template_not_found: 2

      @doc """
      Renders the given template locally.
      """
      def render(template, assigns \\ %{})

      def render(module, template) when is_atom(module) do
        Phoenix.View.render(module, template, %{})
      end

      def render(template, _assigns) when not is_binary(template) do
        raise ArgumentError, "render/2 expects template to be a string, got: #{inspect(template)}"
      end

      def render(template, assigns) when not is_map(assigns) do
        render(template, Enum.into(assigns, %{}))
      end

      @doc "The resource name, as an atom, for this view"
      def __resource__, do: @view_resource
    end
  end

  defp expand_alias({:__aliases__, _, _} = alias, env),
    do: Macro.expand(alias, %{env | function: {:init, 1}})

  defp expand_alias(other, _env), do: other

  @doc ~S'''
  Renders the given layout passing the given `do/end` block
  as `@inner_content`.

  This can be useful to implement nested layouts. For example,
  imagine you have an application layout like this:

      # layout/app.html.heex
      <html>
      <head>
        <title>Title</title>
      </head>
      <body>
        <div class="menu">...</div>
        <%= @inner_content %>
      </body>

  This layout is used by many parts of your application. However,
  there is a subsection of your application that wants to also add
  a sidebar. Let's call it "blog.html". You can build on top of the
  existing layout in two steps. First, define the blog layout:

      # layout/blog.html.heex
      <%= render_layout LayoutView, "app.html", assigns do %>
        <div class="sidebar">...</div>
        <%= @inner_content %>
      <% end %>

  And now you can simply use it from your controller:

      plug :put_layout, "blog.html"

  ## Alternatives

  `render_layout/4` is discouraged in favor of components.
  If you need to share functionality, you can create components
  with bits of functionality you want to reuse. For example,
  the code above could be rewritten with a layout component:

      def layout(assigns) do
        ~H"""
        <div ...>
          <%= render_slot(@sidebar) %>
          <%= render_slot(@inner_block) %>
        </div>
        """
      end

  Which can be used as:

      <.layout>
        Main content
      </.layout>

  Or:

      <.layout>
        <:sidebar>Additional sidebar content</:sidebar>
        Main content
      </.layout>

  The advantage of using components is that you can handle all
  of the sidebar markup inside the parent layout component,
  instead of spreading it across multiple files.
  '''
  def render_layout(module, template, assigns, do: block) do
    assigns =
      assigns
      |> Map.new()
      |> Map.put(:inner_content, block)

    module.render(template, assigns)
  end

  @doc """
  Renders a template.

  It expects the view module, the template as a string, and a
  set of assigns.

  Notice that this function returns the inner representation of a
  template. If you want the encoded template as a result, use
  `render_to_iodata/3` instead.

  ## Examples

      Phoenix.View.render(YourApp.UserView, "index.html", name: "John Doe")
      #=> {:safe, "Hello John Doe"}

  ## Assigns

  Assigns are meant to be user data that will be available in templates.
  However, there are keys under assigns that are specially handled by
  Phoenix, they are:

    * `:layout` - tells Phoenix to wrap the rendered result in the
      given layout. See next section

  ## Layouts

  Templates can be rendered within other templates using the `:layout`
  option. `:layout` accepts a tuple of the form
  `{LayoutModule, "template.extension"}`.

  To template that goes inside the layout will be placed in the `@inner_content`
  assign:

      <%= @inner_content %>

  """
  def render(module, template, assigns)

  def render(module, template, assigns) do
    assigns
    |> Map.new()
    |> Map.pop(:layout, false)
    |> render_within(module, template)
  end

  defp render_within({false, assigns}, module, template) do
    module.render(template, assigns)
  end

  defp render_within({{layout_mod, layout_tpl}, assigns}, module, template)
       when is_atom(layout_mod) and is_binary(layout_tpl) do
    content = module.render(template, assigns)
    assigns = Map.put(assigns, :inner_content, content)
    layout_mod.render(layout_tpl, assigns)
  end

  defp render_within({layout, _assigns}, _module, _template) do
    raise ArgumentError, """
    invalid value for reserved key :layout in View.render/3 assigns

    :layout accepts a tuple of the form {LayoutModule, "template.extension"}

    got: #{inspect(layout)}
    """
  end

  @doc ~S'''
  Renders a template only if it exists.

  > Note: Using this functionality has been discouraged in
  > recent Phoenix versions, see the "Alternatives" section
  > below.

  This function works the same as `render/3`, but returns
  `nil` instead of raising. This is often used with
  `Phoenix.Controller.view_module/1` and `Phoenix.Controller.view_template/1`,
  which must be imported into your views. See the "Examples"
  section below.

  ## Alternatives

  This function is discouraged. If you need to render something
  conditionally, the simplest way is to check for an optional
  function in your views.

  Consider the case where the application has a sidebar in its
  layout and it wants certain views to render additional buttons
  in the sidebar. Inside your sidebar, you could do:

      <div class="sidebar">
        <%= if function_exported?(view_module(@conn), :sidebar_additions, 1) do %>
          <%= view_module(@conn).sidebar_additions(assigns) %>
        <% end %>
      </div>

  If you are using Phoenix.LiveView, you could do similar by
  accessing the view under `@socket`:

      <div class="sidebar">
        <%= if function_exported?(@socket.view, :sidebar_additions, 1) do %>
          <%= @socket.view.sidebar_additions(assigns) %>
        <% end %>
      </div>

  Then, in your view or live view, you do:

      def sidebar_additions(assigns) do
        ~H\"""
        ...my additional buttons...
        \"""

  ## Using render_existing

  Consider the case where the application wants to allow entries
  to be added to a sidebar. This feature could be achieved with:

      <%= render_existing view_module(@conn), "sidebar_additions.html", assigns %>

  Then the module under `view_module(@conn)` can decide to provide
  scripts with either a precompiled template, or by implementing the
  function directly, ie:

      def render("sidebar_additions.html", _assigns) do
        ~H"""
        ...my additional buttons...
        """
      end

  To use a precompiled template, create a `scripts.html.eex` file in
  the `templates` directory for the corresponding view you want it to
  render for. For example, for the `UserView`, create the `scripts.html.eex`
  file at `your_app_web/templates/user/`.
  '''
  def render_existing(module, template, assigns \\ []) do
    assigns = assigns |> Map.new() |> Map.put(:__phx_render_existing__, {module, template})
    render(module, template, assigns)
  end

  @doc """
  Renders a collection.

  It receives a collection as an enumerable of structs and returns
  the rendered collection in a list. This is typically used to render
  a collection as structured data. For example, to render a list of
  users to json:

      render_many(users, UserView, "show.json")

  which is roughly equivalent to:

      Enum.map(users, fn user ->
        render(UserView, "show.json", user: user)
      end)

  The underlying user is passed to the view and template as `:user`,
  which is inferred from the view name. The name of the key
  in assigns can be customized with the `:as` option:

      render_many(users, UserView, "show.json", as: :data)

  is roughly equivalent to:

      Enum.map(users, fn user ->
        render(UserView, "show.json", data: user)
      end)

  """
  def render_many(collection, view, template, assigns \\ %{}) do
    assigns = Map.new(assigns)
    resource_name = get_resource_name(assigns, view)

    Enum.map(collection, fn resource ->
      render(view, template, Map.put(assigns, resource_name, resource))
    end)
  end

  @doc """
  Renders a single item if not nil.

  The following:

      render_one(user, UserView, "show.json")

  is roughly equivalent to:

      if user != nil do
        render(UserView, "show.json", user: user)
      end

  The underlying user is passed to the view and template as
  `:user`, which is inflected from the view name. The name
  of the key in assigns can be customized with the `:as` option:

      render_one(user, UserView, "show.json", as: :data)

  is roughly equivalent to:

      if user != nil do
        render(UserView, "show.json", data: user)
      end

  """
  def render_one(resource, view, template, assigns \\ %{})
  def render_one(nil, _view, _template, _assigns), do: nil

  def render_one(resource, view, template, assigns) do
    assigns = Map.new(assigns)
    render(view, template, assign_resource(assigns, view, resource))
  end

  @compile {:inline, [get_resource_name: 2]}

  defp get_resource_name(assigns, view) do
    case assigns do
      %{as: as} -> as
      _ -> view.__resource__()
    end
  end

  defp assign_resource(assigns, view, resource) do
    Map.put(assigns, get_resource_name(assigns, view), resource)
  end

  @doc """
  Renders the template and returns iodata.
  """
  def render_to_iodata(module, template, assign) do
    render(module, template, assign) |> encode(template)
  end

  @doc """
  Renders the template and returns a string.
  """
  def render_to_string(module, template, assign) do
    render_to_iodata(module, template, assign) |> IO.iodata_to_binary()
  end

  defp encode(content, template) do
    "." <> format = Path.extname(template)

    if encoder = Template.format_encoder(format) do
      encoder.encode_to_iodata!(content)
    else
      content
    end
  end

  @doc """
  Converts the template path into the template name.

  ## Examples

      iex> Phoenix.View.template_path_to_name(
      ...>   "lib/templates/admin/users/show.html.eex",
      ...>   "lib/templates"
      ...> )
      "admin/users/show.html"

  """
  @spec template_path_to_name(Path.t(), Path.t()) :: Path.t()
  def template_path_to_name(path, root) do
    path
    |> Path.rootname()
    |> Path.relative_to(root)
  end

  @doc """
  Converts a module, without the suffix, to a template root.

  ## Examples

      iex> Phoenix.View.module_to_template_root(MyApp.UserView, MyApp, "View")
      "user"

      iex> Phoenix.View.module_to_template_root(MyApp.Admin.User, MyApp, "View")
      "admin/user"

      iex> Phoenix.View.module_to_template_root(MyApp.Admin.User, MyApp.Admin, "View")
      "user"

      iex> Phoenix.View.module_to_template_root(MyApp.View, MyApp, "View")
      ""

      iex> Phoenix.View.module_to_template_root(MyApp.View, MyApp.View, "View")
      ""

  """
  def module_to_template_root(module, base, suffix) do
    module
    |> unsuffix(suffix)
    |> Module.split()
    |> Enum.drop(length(Module.split(base)))
    |> Enum.map(&Macro.underscore/1)
    |> join_paths()
  end

  defp join_paths([]), do: ""
  defp join_paths(paths), do: Path.join(paths)

  defp unsuffix(value, suffix) do
    string = to_string(value)
    suffix_size = byte_size(suffix)
    prefix_size = byte_size(string) - suffix_size

    case string do
      <<prefix::binary-size(prefix_size), ^suffix::binary>> -> prefix
      _ -> string
    end
  end

  ## Exceptions

  # Defined on Phoenix.Template for backwards compatibility
  defmodule Elixir.Phoenix.Template.UndefinedError do
    @moduledoc """
    Exception raised when a template cannot be found.
    """
    defexception [:available, :template, :module, :root, :assigns, :pattern]

    def message(exception) do
      "Could not render #{inspect(exception.template)} for #{inspect(exception.module)}, " <>
        "please define a matching clause for render/2 or define a template at " <>
        "#{inspect(Path.join(Path.relative_to_cwd(exception.root), exception.pattern))}. " <>
        available_templates(exception.available) <>
        "\nAssigns:\n\n" <>
        inspect(exception.assigns) <>
        "\n\nAssigned keys: #{inspect(Map.keys(exception.assigns))}\n"
    end

    defp available_templates([]), do: "No templates were compiled for this module."

    defp available_templates(available) do
      "The following templates were compiled:\n\n" <>
        Enum.map_join(available, "\n", &"* #{&1}") <>
        "\n"
    end
  end

  @private_assigns [:__phx_template_not_found__]

  @doc false
  def __not_found__!(view_module, template, assigns) do
    {root, pattern, names} = view_module.__templates__()

    raise Template.UndefinedError,
      assigns: Map.drop(assigns, @private_assigns),
      available: names,
      template: template,
      root: root,
      pattern: pattern,
      module: view_module
  end

  ## On use callbacks

  @doc false
  def __setup__(module, opts) do
    if Module.get_attribute(module, :view_resource) do
      raise ArgumentError,
            "use Phoenix.View is being called twice in the module #{module}. " <>
              "Make sure to call it only once per module"
    else
      view_resource = String.to_atom(resource_name(module, "View"))
      Module.put_attribute(module, :view_resource, view_resource)
    end

    Module.put_attribute(module, :before_compile, Phoenix.View)
    root = opts[:root] || raise(ArgumentError, "expected :root to be given as an option")
    path = opts[:path]

    namespace =
      if given = opts[:namespace] do
        given
      else
        module
        |> Module.split()
        |> Enum.take(1)
        |> Module.concat()
      end

    root = Path.join(root, path || module_to_template_root(module, namespace, "View"))
    Module.put_attribute(module, :phoenix_root, Path.relative_to_cwd(root))
    Module.put_attribute(module, :phoenix_pattern, Keyword.get(opts, :pattern, "*"))

    engines = Enum.into(Keyword.get(opts, :template_engines, []), Phoenix.Template.engines())
    Module.put_attribute(module, :phoenix_engines, engines)
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote generated: true, unquote: false do
      require Phoenix.Template

      names =
        for {name, _path} <-
              Phoenix.Template.compile_all(
                &Phoenix.View.template_path_to_name(&1, @phoenix_root),
                @phoenix_root,
                @phoenix_pattern,
                @phoenix_engines
              ) do
          defp render_template(unquote(name), assigns) do
            unquote(String.to_atom(name))(assigns)
          end

          name
        end

      # Catch-all clause for template rendering.
      defp render_template(template, %{__phx_render_existing__: {__MODULE__, template}}) do
        nil
      end

      defp render_template(template, %{__phx_template_not_found__: __MODULE__} = assigns) do
        Phoenix.View.__not_found__!(__MODULE__, template, assigns)
      end

      defp render_template(template, assigns) do
        template_not_found(template, Map.put(assigns, :__phx_template_not_found__, __MODULE__))
      end

      # Catch-all clause for rendering.
      def render(template, assigns) do
        render_template(template, assigns)
      end

      @doc false
      def __templates__ do
        {@phoenix_root, @phoenix_pattern, unquote(names)}
      end
    end
  end

  defp resource_name(alias, suffix) do
    alias
    |> to_string()
    |> Module.split()
    |> List.last()
    |> unsuffix(suffix)
    |> Macro.underscore()
  end
end

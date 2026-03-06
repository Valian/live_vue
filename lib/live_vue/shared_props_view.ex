defmodule LiveVue.SharedPropsView do
  @moduledoc """
  HEEX sigil override that injects LiveVue shared props into every `<.vue ...>` tag.

  Shared props are configured via `config :live_vue, :shared_props` and automatically
  injected into all `<.vue>` tags at compile time, so LiveView's change tracking
  works correctly (unlike the old runtime-based shared_props which was removed in v1.0).

  ## Configuration

  In your `config/config.exs`:

      config :live_vue,
        shared_props: [
          :flash,
          {:current_user, :user},
          {[:current_scope, :workspace], :workspace}
        ]

  Supported formats:
    * `:atom` - maps `assigns[:atom]` to a prop named `atom`
    * `{:source, :target}` - maps `assigns[:source]` to a prop named `target`
    * `{[:nested, :path], :target}` - maps `get_in(assigns, [:nested, :path])` to a prop named `target`

  ## Setup

  In your `lib/my_app_web.ex`, override the `~H` sigil in contexts that use `<.vue>` tags:

      defp html_helpers do
        quote do
          # ... existing imports ...
          use LiveVue

          # Override ~H to inject shared props into <.vue> tags
          import Phoenix.Component, except: [sigil_H: 2]
          import LiveVue.SharedPropsView, only: [sigil_H: 2]
        end
      end

  This works by rewriting the HEEX template string at compile time, injecting shared props
  as explicit attributes before the template is compiled by Phoenix. This preserves
  LiveView's reactivity since the props appear as regular template expressions.
  """

  @shared_props_config Application.compile_env(:live_vue, :shared_props, [])

  @doc """
  Override for `~H` that injects shared attrs into every `<.vue ...>` tag.
  """
  defmacro sigil_H({:<<>>, meta, [expr]}, modifiers) when modifiers == [] or modifiers == ~c"noformat" do
    ensure_assigns!(__CALLER__, :H)
    expr = inject_shared_props_in_vue(expr)
    compile_heex(expr, meta, __CALLER__)
  end

  defmacro sigil_H(_term, modifiers) do
    raise ArgumentError, "~H only supports [] or `noformat` modifiers, got: #{inspect(modifiers)}"
  end

  @doc """
  Rewrites a HEEX template string, injecting shared props into `<.vue>` tags.

  Props already present on a tag are not duplicated.
  """
  def inject_shared_props_in_vue(template, shared_props \\ @shared_props_config)

  def inject_shared_props_in_vue(template, shared_props) when is_binary(template) do
    shared_vue_attrs = Enum.map(shared_props, &shared_prop_to_attr!/1)

    Regex.replace(~r/<\.vue\b(.*?)(\/?>)/s, template, fn _full, attrs, close ->
      missing_attrs =
        Enum.reject(shared_vue_attrs, fn {name, _expr} ->
          Regex.match?(~r/\b#{Regex.escape(name)}\s*=/, attrs)
        end)

      injected =
        Enum.map_join(missing_attrs, "", fn {name, expr} ->
          "\n      #{name}={#{expr}}"
        end)

      "<.vue#{attrs}#{injected}#{close}"
    end)
  end

  @doc false
  def shared_prop_to_attr!(prop) when is_atom(prop) do
    {Atom.to_string(prop), path_expr([prop])}
  end

  def shared_prop_to_attr!({source, target}) when is_atom(source) and is_atom(target) do
    {Atom.to_string(target), path_expr([source])}
  end

  def shared_prop_to_attr!({source_path, target}) when is_list(source_path) and is_atom(target) do
    if Enum.all?(source_path, &is_atom/1) do
      {Atom.to_string(target), path_expr(source_path)}
    else
      raise ArgumentError,
            "invalid :live_vue, :shared_props path #{inspect(source_path)}; expected list of atoms"
    end
  end

  def shared_prop_to_attr!(invalid) do
    raise ArgumentError,
          "invalid entry in :live_vue, :shared_props: #{inspect(invalid)}. " <>
            "Expected :prop, {:source, :prop}, or {[:nested, :source], :prop}"
  end

  defp path_expr(path) do
    "get_in(assigns, #{inspect(path)})"
  end

  defp ensure_assigns!(caller, sigil_name) do
    if not Macro.Env.has_var?(caller, {:assigns, nil}) do
      raise "~#{sigil_name} requires a variable named \"assigns\" to exist and be set to a map"
    end
  end

  defp compile_heex(expr, meta, caller) do
    Phoenix.LiveView.TagEngine.compile(expr,
      file: caller.file,
      line: caller.line + 1,
      caller: caller,
      indentation: meta[:indentation] || 0,
      tag_handler: Phoenix.LiveView.HTMLEngine
    )
  end
end

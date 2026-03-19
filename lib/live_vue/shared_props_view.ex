defmodule LiveVue.SharedPropsView do
  @moduledoc """
  HEEX sigil override that injects LiveVue shared props and `v-socket` into every `<.vue ...>`
  tag and LiveVue shortcut component tag.

  Shared props are configured via `config :live_vue, :shared_props` and automatically
  injected into all literal `<.vue>` tags and LiveVue shortcut component tags at compile time,
  together with a builtin `v-socket={get_in(assigns, [:socket])}` attribute when one is not
  already present. That keeps LiveView's change tracking working correctly (unlike the old
  runtime-based shared_props which was removed in v1.0).

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

  In your `lib/my_app_web.ex`, override the `~H` sigil in contexts that use LiveVue component tags:

      defp html_helpers do
        quote do
          # ... existing imports ...
          use LiveVue

          # Override ~H to inject shared props and v-socket into LiveVue tags
          import Phoenix.Component, except: [sigil_H: 2]
          import LiveVue.SharedPropsView, only: [sigil_H: 2]
        end
      end

  This works by rewriting the HEEX template string at compile time, injecting shared props and
  `v-socket` as explicit attributes before the template is compiled by Phoenix. This preserves
  LiveView's reactivity since the props appear as regular template expressions.
  """

  @shared_props_config Application.compile_env(:live_vue, :shared_props, [])

  @doc """
  Override for `~H` that injects shared attrs and `v-socket` into LiveVue tags.
  """
  defmacro sigil_H({:<<>>, meta, [expr]}, modifiers) when modifiers == [] or modifiers == ~c"noformat" do
    ensure_assigns!(__CALLER__, :H)
    expr = inject_shared_props_in_vue(expr, @shared_props_config, __CALLER__)
    compile_heex(expr, meta, __CALLER__)
  end

  defmacro sigil_H(_term, modifiers) do
    raise ArgumentError, "~H only supports [] or `noformat` modifiers, got: #{inspect(modifiers)}"
  end

  @doc """
  Rewrites a HEEX template string, injecting shared props and `v-socket` into LiveVue tags.

  Props already present on a tag are not duplicated.
  """
  def inject_shared_props_in_vue(template, shared_props \\ @shared_props_config)

  def inject_shared_props_in_vue(template, shared_props) when is_binary(template) do
    inject_shared_props_in_vue(template, shared_props, nil)
  end

  @doc false
  def inject_shared_props_in_vue(template, shared_props, caller) when is_binary(template) do
    shared_vue_attrs = Enum.map(shared_props, &shared_prop_to_attr!/1)

    # Always inject v-socket if not already present
    builtin_attrs = [{"v-socket", "get_in(assigns, [:socket])"}]

    rewrite_live_vue_tags(template, builtin_attrs ++ shared_vue_attrs, caller)
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

  defp rewrite_live_vue_tags(template, attrs_to_inject, caller) do
    do_rewrite_live_vue_tags(template, attrs_to_inject, caller, [])
  end

  defp do_rewrite_live_vue_tags(template, attrs_to_inject, caller, acc) do
    case :binary.match(template, "<.") do
      :nomatch ->
        IO.iodata_to_binary(Enum.reverse([template | acc]))

      {index, 2} ->
        <<prefix::binary-size(index), rest::binary>> = template

        case parse_local_component_tag(rest) do
          {:ok, tag_name, attrs, close, remainder} ->
            tag =
              if live_vue_tag?(tag_name, caller) do
                inject_missing_attrs(tag_name, attrs, close, attrs_to_inject)
              else
                ["<.", tag_name, attrs, close]
              end

            do_rewrite_live_vue_tags(remainder, attrs_to_inject, caller, [tag, prefix | acc])

          :error ->
            <<tag_start::binary-size(2), remainder::binary>> = rest
            do_rewrite_live_vue_tags(remainder, attrs_to_inject, caller, [tag_start, prefix | acc])
        end
    end
  end

  defp parse_local_component_tag(<<"<.", rest::binary>>) do
    case take_tag_name(rest, []) do
      {"", _rest} ->
        :error

      {tag_name, rest} ->
        case take_tag_attrs(rest, [], nil, 0) do
          {:ok, attrs, close, remainder} -> {:ok, tag_name, attrs, close, remainder}
          :error -> :error
        end
    end
  end

  defp take_tag_name(<<char::utf8, rest::binary>>, acc)
       when char in ?0..?9 or char in ?A..?Z or char in ?a..?z or char in [?_, ??, ?!] do
    take_tag_name(rest, [<<char::utf8>> | acc])
  end

  defp take_tag_name(rest, acc) do
    {IO.iodata_to_binary(Enum.reverse(acc)), rest}
  end

  defp take_tag_attrs(<<>>, _acc, _quote, _brace_depth), do: :error

  defp take_tag_attrs(<<"/", ">", rest::binary>>, acc, nil, 0) do
    {:ok, IO.iodata_to_binary(Enum.reverse(acc)), "/>", rest}
  end

  defp take_tag_attrs(<<">", rest::binary>>, acc, nil, 0) do
    {:ok, IO.iodata_to_binary(Enum.reverse(acc)), ">", rest}
  end

  defp take_tag_attrs(<<?\\, escaped::utf8, rest::binary>>, acc, {:expr, quote_char}, brace_depth) do
    take_tag_attrs(rest, [<<escaped::utf8>>, <<?\\>> | acc], {:expr, quote_char}, brace_depth)
  end

  defp take_tag_attrs(<<quote_char::utf8, rest::binary>>, acc, {_kind, quote_char}, brace_depth) do
    take_tag_attrs(rest, [<<quote_char::utf8>> | acc], nil, brace_depth)
  end

  defp take_tag_attrs(<<char::utf8, rest::binary>>, acc, nil, brace_depth) when char in [?", ?'] do
    quote_kind = if brace_depth > 0, do: :expr, else: :html
    take_tag_attrs(rest, [<<char::utf8>> | acc], {quote_kind, char}, brace_depth)
  end

  defp take_tag_attrs(<<?{, rest::binary>>, acc, nil, brace_depth) do
    take_tag_attrs(rest, [<<?{>> | acc], nil, brace_depth + 1)
  end

  defp take_tag_attrs(<<?}, rest::binary>>, acc, nil, brace_depth) when brace_depth > 0 do
    take_tag_attrs(rest, [<<?}>> | acc], nil, brace_depth - 1)
  end

  defp take_tag_attrs(<<char::utf8, rest::binary>>, acc, quote, brace_depth) do
    take_tag_attrs(rest, [<<char::utf8>> | acc], quote, brace_depth)
  end

  defp inject_missing_attrs(tag_name, attrs, close, attrs_to_inject) do
    missing_attrs =
      Enum.reject(attrs_to_inject, fn {name, _expr} ->
        Regex.match?(~r/\b#{Regex.escape(name)}\s*=/, attrs)
      end)

    injected =
      Enum.map(missing_attrs, fn {name, expr} ->
        ["\n      ", name, "={", expr, "}"]
      end)

    ["<.", tag_name, attrs, injected, close]
  end

  defp live_vue_tag?("vue", _caller), do: true
  defp live_vue_tag?(_tag_name, nil), do: false

  defp live_vue_tag?(tag_name, caller) do
    module = component_module(tag_name, caller)
    tag_name in live_vue_shortcuts(module, caller)
  end

  defp component_module(tag_name, caller) do
    fun = String.to_atom(tag_name)

    case Macro.Env.lookup_import(caller, {fun, 1}) do
      [{_, module} | _] -> module
      _ -> caller.module
    end
  end

  defp live_vue_shortcuts(module, caller) when module == caller.module do
    if function_exported?(module, :__live_vue_shortcuts__, 0) do
      module.__live_vue_shortcuts__()
    else
      Module.get_attribute(module, :live_vue_shortcuts) || []
    end
  end

  defp live_vue_shortcuts(module, _caller) do
    if function_exported?(module, :__live_vue_shortcuts__, 0) do
      module.__live_vue_shortcuts__()
    else
      []
    end
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

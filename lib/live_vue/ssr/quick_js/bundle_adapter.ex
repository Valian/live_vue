defmodule LiveVue.SSR.QuickJS.BundleAdapter do
  @moduledoc false

  @doc """
  Transforms a Vite SSR bundle for evaluation in QuickJS.

  Stubs Node.js built-in imports (`fs`, `path`, `node:stream`) and
  converts `export { ... }` to `globalThis` assignments.
  """
  def adapt(code) do
    code
    |> stub_node_imports()
    |> expose_exports()
  end

  defp stub_node_imports(code) do
    code
    |> String.replace(
      ~r/^import\s+\S+\s+from\s+["']fs["'];?\s*$/m,
      "const fs = { readFileSync: function() { return '{}'; } };"
    )
    |> String.replace(
      ~r/^import\s+\{[^}]+\}\s+from\s+["']path["'];?\s*$/m,
      ~s[const resolve = function() { return Array.from(arguments).join('/'); };\n] <>
        ~s[const basename = function(p) { return p.split('/').pop(); };]
    )
    |> String.replace(
      ~r/^import\s+\S+\s+from\s+["']node:stream["'];?\s*$/m,
      "const require$$3 = { Readable: function() {} };"
    )
  end

  defp expose_exports(code) do
    Regex.replace(
      ~r/^export\s*\{([^}]+)\};?\s*$/m,
      code,
      fn _, captures ->
        captures
        |> String.split(",")
        |> Enum.map_join("\n", fn name ->
          name = String.trim(name)
          "globalThis.#{name} = #{name};"
        end)
      end
    )
  end
end

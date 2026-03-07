defmodule LiveVue.SSR.QuickJSTest do
  use ExUnit.Case, async: false

  alias LiveVue.SSR.QuickJS, as: QuickJSRenderer

  @moduletag :quickjs_ssr
  @test_server_path Path.expand("support/ssr_test_server_quickjs.js", __DIR__)

  describe "render/3 with QuickJS runtime" do
    setup do
      {:ok, rt} = QuickJSEx.start(name: QuickJSRenderer)

      bundle = File.read!(@test_server_path)

      case QuickJSEx.eval(rt, bundle) do
        {:ok, _} -> :ok
        {:error, "Value is not JSON-serializable"} -> :ok
      end

      on_exit(fn ->
        try do
          QuickJSEx.stop(rt)
        catch
          :exit, _ -> :ok
        end
      end)

      :ok
    end

    test "renders component and returns HTML" do
      result = QuickJSRenderer.render("TestComponent", %{"count" => 42}, %{})

      assert is_binary(result)
      assert result =~ "SSR Rendered: TestComponent"
    end

    test "passes props to the render function" do
      result = QuickJSRenderer.render("MyComponent", %{"name" => "John", "age" => 30}, %{})

      assert result =~ "John"
      assert result =~ "30"
    end

    test "passes slots to the render function" do
      result = QuickJSRenderer.render("SlotComponent", %{}, %{"default" => "<p>Content</p>"})

      assert result =~ "Content"
    end

    test "handles preload links delimiter" do
      result = QuickJSRenderer.render("WithPreloadLinks", %{}, %{})

      assert result =~ "<link"
      assert result =~ "<!-- preload -->"
    end

    test "raises on render error" do
      assert_raise RuntimeError, ~r/QuickJS SSR render failed/, fn ->
        QuickJSRenderer.render("Error", %{}, %{})
      end
    end
  end

  describe "bundle adaptation" do
    test "stubs fs import" do
      code = ~s[import fs from "fs";\nconsole.log("ok");]
      adapted = apply_adapt(code)

      refute adapted =~ "import fs"
      assert adapted =~ "readFileSync"
    end

    test "stubs path import" do
      code = ~s[import { resolve, basename } from "path";\nconsole.log("ok");]
      adapted = apply_adapt(code)

      refute adapted =~ ~s[from "path"]
      assert adapted =~ "resolve"
      assert adapted =~ "basename"
    end

    test "stubs node:stream import" do
      code = ~s[import require$$3 from "node:stream";\nconsole.log("ok");]
      adapted = apply_adapt(code)

      refute adapted =~ ~s[from "node:stream"]
      assert adapted =~ "require$$3"
    end

    test "converts single export to globalThis" do
      code = "const render = () => {};\nexport { render };"
      adapted = apply_adapt(code)

      refute adapted =~ "export"
      assert adapted =~ "globalThis.render = render;"
    end

    test "converts multiple exports to globalThis" do
      code = "const a = 1;\nconst b = 2;\nexport { a, b };"
      adapted = apply_adapt(code)

      assert adapted =~ "globalThis.a = a;"
      assert adapted =~ "globalThis.b = b;"
    end

    test "preserves non-Node.js code" do
      code = "function hello() { return 'world'; }"
      assert apply_adapt(code) == code
    end
  end

  defp apply_adapt(code) do
    code
    |> QuickJSRenderer.__stub_node_imports__()
    |> QuickJSRenderer.__expose_exports__()
  end
end

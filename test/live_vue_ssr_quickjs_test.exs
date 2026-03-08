defmodule LiveVue.SSR.QuickJSTest do
  use ExUnit.Case, async: false

  alias LiveVue.SSR.QuickJS, as: QuickJSRenderer

  @moduletag :quickjs_ssr
  @test_server_path Path.expand("support/ssr_test_server_quickjs.js", __DIR__)

  describe "render/3 with QuickJS runtime" do
    setup do
      {:ok, rt} = QuickJSEx.start(name: QuickJSRenderer)

      bundle = File.read!(@test_server_path)
      :ok = QuickJSEx.load_module(rt, "server", bundle)

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
end

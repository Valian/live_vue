defmodule LiveVue.SSR.QuickBEAMTest do
  use ExUnit.Case, async: false

  alias LiveVue.SSR.QuickBEAM, as: QuickBEAMRenderer

  @moduletag :quickbeam_ssr
  @test_server_path Path.expand("support/ssr_test_server_quickbeam.js", __DIR__)

  describe "render/3 with QuickBEAM runtime" do
    setup do
      {:ok, rt} = QuickBEAM.start(name: QuickBEAMRenderer)

      bundle = File.read!(@test_server_path)
      bridged = bundle <> "\nglobalThis.render = render;\n"
      :ok = QuickBEAM.load_module(rt, "server", bridged)

      on_exit(fn ->
        try do
          QuickBEAM.stop(rt)
        catch
          :exit, _ -> :ok
        end
      end)

      :ok
    end

    test "renders component and returns HTML" do
      result = QuickBEAMRenderer.render("TestComponent", %{"count" => 42}, %{})

      assert is_binary(result)
      assert result =~ "SSR Rendered: TestComponent"
    end

    test "passes props to the render function" do
      result = QuickBEAMRenderer.render("MyComponent", %{"name" => "John", "age" => 30}, %{})

      assert result =~ "John"
      assert result =~ "30"
    end

    test "passes slots to the render function" do
      result = QuickBEAMRenderer.render("SlotComponent", %{}, %{"default" => "<p>Content</p>"})

      assert result =~ "Content"
    end

    test "handles preload links delimiter" do
      result = QuickBEAMRenderer.render("WithPreloadLinks", %{}, %{})

      assert result =~ "<link"
      assert result =~ "<!-- preload -->"
    end

    test "raises on render error" do
      assert_raise RuntimeError, ~r/QuickBEAM SSR render failed/, fn ->
        QuickBEAMRenderer.render("Error", %{}, %{})
      end
    end
  end
end

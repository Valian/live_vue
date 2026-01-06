defmodule LiveVue.SSR.NodeJSTest do
  use ExUnit.Case

  alias LiveVue.SSR.NodeJS, as: NodeJSRenderer

  @moduletag :nodejs_ssr

  # Path to our test support directory
  @test_support_path Path.expand("support", __DIR__)
  # Just the filename - NodeJS.Supervisor resolves relative to its path
  @test_server_filename "ssr_test_server.mjs"

  describe "render/3 with NodeJS.Supervisor running" do
    setup do
      # Start NodeJS.Supervisor for this test (from the nodejs package)
      # The path should be the directory containing our test server
      start_supervised!({NodeJS.Supervisor, [path: @test_support_path, pool_size: 1]})

      # Configure to use our test server - just the filename since NodeJS resolves relative to path
      Application.put_env(:live_vue, :ssr_filepath, @test_server_filename)

      on_exit(fn ->
        Application.delete_env(:live_vue, :ssr_filepath)
      end)

      :ok
    end

    test "renders component and returns HTML" do
      result = NodeJSRenderer.render("TestComponent", %{"count" => 42}, %{})

      assert is_binary(result)
      assert result =~ "SSR Rendered: TestComponent"
      assert result =~ "TestComponent"
    end

    test "passes props to the render function" do
      result = NodeJSRenderer.render("MyComponent", %{"name" => "John", "age" => 30}, %{})

      assert result =~ "John"
      assert result =~ "30"
    end

    test "passes slots to the render function" do
      result = NodeJSRenderer.render("SlotComponent", %{}, %{"default" => "<p>Content</p>"})

      assert result =~ "Content"
    end

    test "handles preload links delimiter" do
      result = NodeJSRenderer.render("WithPreloadLinks", %{}, %{})

      assert result =~ "<link"
      assert result =~ "<!-- preload -->"
    end
  end

  describe "render/3 without NodeJS.Supervisor" do
    test "raises NotConfigured when NodeJS.Supervisor is not running" do
      # Make sure no supervisor is running
      # Configure to use our test server filename
      Application.put_env(:live_vue, :ssr_filepath, @test_server_filename)

      on_exit(fn ->
        Application.delete_env(:live_vue, :ssr_filepath)
      end)

      assert_raise LiveVue.SSR.NotConfigured,
                   ~r/NodeJS is not configured/,
                   fn ->
                     NodeJSRenderer.render("TestComponent", %{}, %{})
                   end
    end
  end

  describe "server_path/0" do
    test "raises MatchError when called outside application context" do
      # server_path/0 uses :application.get_application() which returns :undefined
      # when called outside of application context (like in tests)
      # This is expected behavior - use server_path/1 instead for reliable paths
      assert_raise MatchError, fn ->
        NodeJSRenderer.server_path()
      end
    end
  end

  describe "server_path/1" do
    test "returns the priv directory path for the given application" do
      # server_path/1 takes an explicit app name and returns its priv directory
      path = NodeJSRenderer.server_path(:live_vue)

      assert is_binary(path)
      assert String.ends_with?(path, "/priv")
      assert String.contains?(path, "live_vue")
    end

    test "works with any valid application atom" do
      # Should work with any loaded application
      path = NodeJSRenderer.server_path(:elixir)

      assert is_binary(path)
      assert String.ends_with?(path, "/priv")
    end
  end
end

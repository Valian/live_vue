defmodule LiveVue.SSRTest do
  use ExUnit.Case

  alias LiveVue.SSR

  defmodule MockSSRRenderer do
    @moduledoc false
    @behaviour SSR

    @impl true
    def render("WithPreload", _props, _slots) do
      "<link rel=\"preload\" /><!-- preload --><div>Component HTML</div>"
    end

    @impl true
    def render("NoPreload", _props, _slots) do
      "<div>Just HTML</div>"
    end

    @impl true
    def render("MapResponse", _props, _slots) do
      %{preloadLinks: "<link rel=\"stylesheet\" />", html: "<div>Direct map</div>"}
    end

    @impl true
    def render("Echo", props, slots) do
      props_str = Jason.encode!(props)
      slots_str = Jason.encode!(slots)
      "<div>Props: #{props_str}, Slots: #{slots_str}</div>"
    end
  end

  setup do
    # Clean up config after each test
    on_exit(fn ->
      Application.delete_env(:live_vue, :ssr_module)
    end)

    :ok
  end

  describe "render/3 when ssr_module is not configured" do
    test "returns empty map with empty strings" do
      Application.delete_env(:live_vue, :ssr_module)

      result = SSR.render("AnyComponent", %{}, %{})

      assert result == %{preloadLinks: "", html: ""}
    end

    test "ignores props and slots when not configured" do
      Application.delete_env(:live_vue, :ssr_module)

      result = SSR.render("Component", %{"key" => "value"}, %{"slot" => "content"})

      assert result == %{preloadLinks: "", html: ""}
    end
  end

  describe "render/3 when ssr_module is configured" do
    setup do
      Application.put_env(:live_vue, :ssr_module, MockSSRRenderer)
      :ok
    end

    test "splits response on <!-- preload --> delimiter" do
      result = SSR.render("WithPreload", %{}, %{})

      assert result == %{
               preloadLinks: "<link rel=\"preload\" />",
               html: "<div>Component HTML</div>"
             }
    end

    test "handles response without preload delimiter" do
      result = SSR.render("NoPreload", %{}, %{})

      assert result == %{
               preloadLinks: "",
               html: "<div>Just HTML</div>"
             }
    end

    test "passes through map response directly" do
      result = SSR.render("MapResponse", %{}, %{})

      assert result == %{
               preloadLinks: "<link rel=\"stylesheet\" />",
               html: "<div>Direct map</div>"
             }
    end

    test "forwards component name, props, and slots to renderer" do
      props = %{"count" => 42, "title" => "Test"}
      slots = %{"default" => "<span>Content</span>"}

      result = SSR.render("Echo", props, slots)

      assert result.html =~ "\"count\":42"
      assert result.html =~ ~s("title":"Test")
      assert result.html =~ ~s("default":"<span>Content</span>")
    end
  end

  describe "render/3 telemetry" do
    setup do
      Application.put_env(:live_vue, :ssr_module, MockSSRRenderer)

      # Attach telemetry handler
      handler_id = :telemetry_test_handler
      test_pid = self()

      :telemetry.attach(
        handler_id,
        [:live_vue, :ssr, :start],
        fn event, measurements, metadata, _config ->
          send(test_pid, {:telemetry_event, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn ->
        :telemetry.detach(handler_id)
      end)

      :ok
    end

    test "emits telemetry span with correct metadata" do
      props = %{"key" => "value"}
      slots = %{"header" => "Header content"}

      SSR.render("NoPreload", props, slots)

      assert_receive {:telemetry_event, [:live_vue, :ssr, :start], _measurements, metadata}

      assert metadata.component == "NoPreload"
      assert metadata.props == %{"key" => "value"}
      assert metadata.slots == %{"header" => "Header content"}
    end

    test "emits telemetry for each render call" do
      SSR.render("WithPreload", %{}, %{})
      SSR.render("NoPreload", %{}, %{})

      assert_receive {:telemetry_event, [:live_vue, :ssr, :start], _, %{component: "WithPreload"}}
      assert_receive {:telemetry_event, [:live_vue, :ssr, :start], _, %{component: "NoPreload"}}
    end
  end

  describe "render/3 edge cases" do
    defmodule EdgeCaseRenderer do
      @moduledoc false
      @behaviour SSR

      @impl true
      def render("MultipleDelimiters", _props, _slots) do
        "<link /><!-- preload --><div><!-- preload -->Another one</div>"
      end

      @impl true
      def render("EmptyPreload", _props, _slots) do
        "<!-- preload --><div>No preload links</div>"
      end

      @impl true
      def render("EmptyHTML", _props, _slots) do
        "<link /><!-- preload -->"
      end
    end

    setup do
      Application.put_env(:live_vue, :ssr_module, EdgeCaseRenderer)
      :ok
    end

    test "splits only on first delimiter with multiple delimiters" do
      result = SSR.render("MultipleDelimiters", %{}, %{})

      assert result == %{
               preloadLinks: "<link />",
               html: "<div><!-- preload -->Another one</div>"
             }
    end

    test "handles empty preload section" do
      result = SSR.render("EmptyPreload", %{}, %{})

      assert result == %{
               preloadLinks: "",
               html: "<div>No preload links</div>"
             }
    end

    test "handles empty HTML section" do
      result = SSR.render("EmptyHTML", %{}, %{})

      assert result == %{
               preloadLinks: "<link />",
               html: ""
             }
    end
  end

  describe "LiveVue.SSR.NotConfigured exception" do
    test "can be raised with a message" do
      assert_raise SSR.NotConfigured, "SSR is not configured", fn ->
        raise SSR.NotConfigured, message: "SSR is not configured"
      end
    end
  end
end

defmodule LiveVue.SSR.NotConfigured do
  @moduledoc false

  defexception [:message]
end

defmodule LiveVue.SSR do
  require Logger

  @moduledoc """
  A behaviour for rendering Vue components server-side.

  To define a custom renderer, change the application config in `config.exs`:

      config :live_vue, ssr_module: MyCustomSSRModule

  Exposes a telemetry span for each render under key `[:live_vue, :ssr]`
  """

  @type component_name :: String.t()
  @type props :: %{optional(String.t() | atom) => any}
  @type slots :: %{optional(String.t() | atom) => any}

  @typedoc """
  A render response which should be a rendered HTML string.
      }
  """
  @type render_response :: String.t()

  @callback render(component_name, props, slots) :: render_response | no_return

  @spec render(component_name, props, slots) :: render_response | no_return
  def render(name, props, slots) do
    case Application.get_env(:live_vue, :ssr_module, nil) do
      nil ->
        ""

      mod ->
        meta = %{component: name, props: props, slots: slots}

        :telemetry.span([:live_vue, :ssr], meta, fn ->
          {mod.render(name, props, slots), meta}
        end)
    end
  end
end

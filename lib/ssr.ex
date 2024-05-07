defmodule LiveVue.SSR.NotConfigured do
  @moduledoc false

  defexception [:message]
end

defmodule LiveVue.SSR do
  @moduledoc """
  A behaviour for rendering Vue components server-side.

  To define a custom renderer, change the application config in `config.exs`:

      config :live_vue, ssr_module: MyCustomSSRModule
  """

  @type component_name :: String.t()
  @type props :: %{optional(String.t() | atom) => any}
  @type slots :: %{optional(String.t() | atom) => any}

  @typedoc """
  A render response which should take the shape:
      %{
        "css" => %{
          "code" => String.t | nil,
          "map" => String.t | nil
        },
        "head" => String.t,
        "html" => String.t
      }
  """
  @type render_response :: %{
          required(String.t()) =>
            %{
              required(String.t()) => String.t() | nil
            }
            | String.t()
        }

  @callback render(component_name, props, slots) :: render_response | no_return

  @spec render(component_name, props, slots) :: render_response | no_return
  def render(name, props, slots) do
    mod = Application.get_env(:live_vue, :ssr_module, LiveVue.SSR.NodeJS)

    mod.render(name, props, slots)
  end
end

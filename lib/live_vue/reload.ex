defmodule LiveVue.Reload do
  @moduledoc """
  Utilities for easier integration with Vite in development
  """

  use Phoenix.Component

  attr :assets, :list, required: true
  slot :inner_block, required: true, doc: "what should be rendered when Vite path is not defined"

  @doc """
  Renders the vite assets in development, and in production falls back to normal compiled assets
  """
  def vite_assets(assigns) do
    assigns =
      assigns
      |> assign(:stylesheets, for(path <- assigns.assets, String.ends_with?(path, ".css"), do: path))
      |> assign(:javascripts, for(path <- assigns.assets, String.ends_with?(path, ".js"), do: path))

    # TODO - maybe make it configurable in other way than by presence of vite_host config?
    ~H"""
    <%= if Application.get_env(:live_vue, :vite_host) do %>
      <script type="module" src={LiveVue.SSR.ViteJS.vite_path("@vite/client")}>
      </script>
      <link :for={path <- @stylesheets} rel="stylesheet" href={LiveVue.SSR.ViteJS.vite_path(path)} />
      <script :for={path <- @javascripts} type="module" src={LiveVue.SSR.ViteJS.vite_path(path)}>
      </script>
    <% else %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end
end

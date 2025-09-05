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
      |> assign(:public_host, Application.get_env(:live_vue, :vite_public_host) || Application.get_env(:live_view, :vite_host))

      # TODO - maybe make it configurable in other way than by presence of vite_host config?
    ~H"""
    <%= if @public_host do %>
      <script type="module" src={LiveVue.SSR.ViteJS.vite_path("@vite/client", true)}>
      </script>
      <link :for={path <- @stylesheets} rel="stylesheet" href={LiveVue.SSR.ViteJS.vite_path(path, true)} />
      <script :for={path <- @javascripts} type="module" src={LiveVue.SSR.ViteJS.vite_path(path, true)}>
      </script>
    <% else %>
      {render_slot(@inner_block)}
    <% end %>
    """
  end
end

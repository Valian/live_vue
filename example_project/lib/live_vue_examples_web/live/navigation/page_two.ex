defmodule LiveVueExamplesWeb.Navigation.PageTwo do
  use LiveVueExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header>Navigation example: Page Two</.header>
    <.vue v-component="NavigationExample" params={@params} v-socket={@socket} />
    """
  end

  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, :params, params)}
  end
end

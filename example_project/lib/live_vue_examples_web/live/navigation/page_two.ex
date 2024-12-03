defmodule LiveVueExamplesWeb.Navigation.PageTwo do
  use LiveVueExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header>Navigation example: Page Two</.header>
    <.vue
      v-component="NavigationExample"
      page="Two"
      other-page="One"
      other-page-path={~p"/navigation/page_one"}
      params={@params}
      v-socket={@socket}
      v-ssr={false}
    />
    """
  end

  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, :params, params)}
  end
end

defmodule LiveVueExamplesWeb.Navigation.PageOne do
  use LiveVueExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header>Navigation example: Page one</.header>
    <.vue
      v-component="NavigationExample"
      page="One"
      other-page="Two"
      other-page-path={~p"/navigation/page_two"}
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

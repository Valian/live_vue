defmodule LiveVue.E2E.NavigationLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(params, _session, socket) do
    {:ok, assign(socket, params: params, query_params: %{})}
  end

  def handle_params(params, uri, socket) do
    query_params = URI.parse(uri).query
    parsed_query = if query_params, do: URI.decode_query(query_params), else: %{}
    {:noreply, assign(socket, params: params, query_params: parsed_query)}
  end

  def render(assigns) do
    ~H"""
    <div id="navigation-test">
      <LiveVue.vue params={@params} query_params={@query_params} v-component="navigation" v-socket={@socket} />
    </div>
    """
  end
end

defmodule LiveVue.E2E.PersistentLayoutLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(_params, _session, socket), do: {:ok, socket}

  def handle_params(%{"page" => page}, _uri, socket) do
    {:noreply, assign(socket, page: page)}
  end

  def render(assigns) do
    ~H"""
    <LiveVue.vue
      v-component="persistent-layout/layout"
      v-socket={@socket}
      id="vue-layout"
      v-ssr={true}
    />
    <LiveVue.vue
      page={@page}
      v-component="persistent-layout/page"
      v-inject="vue-layout"
      v-socket={@socket}
      id="page-component"
      v-ssr={true}
    />
    <LiveVue.vue
      v-component="persistent-layout/nested"
      v-inject="page-component"
      v-socket={@socket}
      message="I'm nested!"
      id="nested-component"
      v-ssr={true}
    />
    <LiveVue.vue
      v-component="persistent-layout/sidebar"
      v-inject:sidebar="vue-layout"
      v-socket={@socket}
      label="Sidebar"
      v-ssr={true}
    />
    """
  end
end

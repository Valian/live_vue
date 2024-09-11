defmodule LiveVueExamplesWeb.CalendarLive do
  use LiveVueExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header>LiveVue Vuetify Calendar</.header>

    <div class="pb-60">
      <.vue id="calendar" v-component="VuetifyCalendar" v-socket={@socket} v-ssr={false} />
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end

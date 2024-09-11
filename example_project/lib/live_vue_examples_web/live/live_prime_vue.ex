defmodule LiveVueExamplesWeb.LivePrimeVue do
  use LiveVueExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header>PrimeVue timeline example</.header>
    <.vue v-component="PrimeVueExample" v-socket={@socket} v-ssr={false} />
    """
  end
end

defmodule LiveVueExamplesWeb.LiveSlots do
  use LiveVueExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header>Slots example</.header>
    <.Card title="The coldest sunset" tags={@tags} v-socket={@socket}>
      <p>This is card content passed from phoenix!</p>
      <p>Even icons are working! <.icon name="hero-information-circle-mini" /></p>
      <p>There are <%= length(@tags) %> tags</p>
      <:footer>And this is a footer from phoenix</:footer>
    </.Card>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, tags: ["sun", "sunset", "winter"])}
  end

  def handle_event("add-tag", _, socket) do
    tag = Enum.random(["nice", "wow", "so cool"])
    # flash is a shared prop, so it's always available for Vue components
    socket = put_flash(socket, :info, "Tag #{tag} added")
    {:noreply, update(socket, :tags, &(&1 ++ [tag]))}
  end
end

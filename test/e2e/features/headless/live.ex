defmodule LiveVue.E2E.HeadlessLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0, label: "Hello")}
  end

  def handle_event("increment", _params, socket) do
    {:noreply, assign(socket, :count, socket.assigns.count + 1)}
  end

  def handle_event("update_label", %{"label" => label}, socket) do
    {:noreply, assign(socket, :label, label)}
  end

  def render(assigns) do
    ~H"""
    <LiveVue.vue id="data-source" count={@count} label={@label} v-socket={@socket} />
    <LiveVue.vue v-component="headless/display" v-socket={@socket} />
    <button data-pw-increment phx-click="increment">Increment</button>
    <form phx-submit="update_label">
      <input type="text" name="label" data-pw-label-input />
      <button type="submit" data-pw-update-label>Update</button>
    </form>
    """
  end
end

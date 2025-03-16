defmodule LiveVueUIExampleWeb.ButtonsLive do
  use Phoenix.LiveView
  import LiveVueUI.Components

  def mount(_params, _session, socket) do
    socket = 
      socket
      |> assign(:page_title, "Button Examples") 
      |> assign(:click_count, 0)
      
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg p-6">
      <div class="mb-8">
        <h2 class="text-xl font-semibold mb-4">Button Variants</h2>
        <div class="flex flex-wrap gap-4">
          <.button>Primary</.button>
          <.button variant={:secondary}>Secondary</.button>
          <.button variant={:outline}>Outline</.button>
          <.button variant={:ghost}>Ghost</.button>
        </div>
      </div>

      <div class="mb-8">
        <h2 class="text-xl font-semibold mb-4">Button Sizes</h2>
        <div class="flex flex-wrap gap-4 items-center">
          <.button size={:sm}>Small</.button>
          <.button size={:md}>Medium</.button>
          <.button size={:lg}>Large</.button>
        </div>
      </div>

      <div class="mb-8">
        <h2 class="text-xl font-semibold mb-4">Disabled Buttons</h2>
        <div class="flex flex-wrap gap-4">
          <.button disabled={true}>Disabled Primary</.button>
          <.button variant={:secondary} disabled={true}>Disabled Secondary</.button>
          <.button variant={:outline} disabled={true}>Disabled Outline</.button>
          <.button variant={:ghost} disabled={true}>Disabled Ghost</.button>
        </div>
      </div>

      <div class="mb-8">
        <h2 class="text-xl font-semibold mb-4">Interactive Buttons</h2>
        <div class="flex flex-wrap gap-4">
          <button 
            phx-click="increment"
            class="px-4 py-2 font-medium rounded focus:outline-none transition-colors bg-blue-600 hover:bg-blue-700 text-white"
          >
            Click me (count: <%= @click_count %>)
          </button>
          
          <button 
            phx-click="decrement"
            class="px-4 py-2 font-medium rounded focus:outline-none transition-colors bg-gray-500 hover:bg-gray-600 text-white"
          >
            Decrement
          </button>
          
          <button 
            phx-click="reset"
            class="px-4 py-2 font-medium rounded focus:outline-none transition-colors bg-transparent border border-blue-600 text-blue-600 hover:bg-blue-50"
          >
            Reset
          </button>
        </div>
        <div class="mt-4 p-4 bg-gray-100 rounded">
          <p class="font-medium">Current count: <%= @click_count %></p>
        </div>
      </div>

      <div class="mb-8">
        <h2 class="text-xl font-semibold mb-4">Custom Styling</h2>
        <div class="flex flex-wrap gap-4">
          <.button class="bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600">
            Gradient Button
          </.button>
          <.button class="rounded-full">
            Rounded Button
          </.button>
          <.button class="border-2 border-blue-600">
            Custom Border
          </.button>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("increment", _params, socket) do
    IO.puts("Increment event received")
    new_count = socket.assigns.click_count + 1
    {:noreply, assign(socket, click_count: new_count)}
  end

  def handle_event("decrement", _params, socket) do
    IO.puts("Decrement event received")
    new_count = max(0, socket.assigns.click_count - 1)
    {:noreply, assign(socket, click_count: new_count)}
  end

  def handle_event("reset", _params, socket) do
    IO.puts("Reset event received")
    {:noreply, assign(socket, click_count: 0)}
  end
end 
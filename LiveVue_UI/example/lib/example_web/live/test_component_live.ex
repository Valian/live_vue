defmodule LiveVueUIExampleWeb.TestComponentLive do
  use Phoenix.LiveView
  import LiveVueUI.Components
  
  def mount(_params, _session, socket) do
    socket = 
      socket
      |> assign(:page_title, "Test Component") 
      |> assign(:count, 0)
      
    {:ok, socket}
  end
  
  def render(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg p-6">
      <p>This is a test page for our LiveVue components. We're using the pre-built components from LiveVueUI.</p>
    
      <div class="mt-4 space-y-4">
        <button 
          phx-click="handle_event"
          class="px-4 py-2 font-medium rounded focus:outline-none transition-colors bg-blue-600 hover:bg-blue-700 text-white"
        >
          Click Me
        </button>
        
        <button 
          phx-click="handle_event"
          class="px-4 py-2 font-medium rounded focus:outline-none transition-colors bg-gray-500 hover:bg-gray-600 text-white"
        >
          Secondary Button
        </button>
        
        <button 
          phx-click="handle_event"
          class="px-4 py-2 font-medium rounded focus:outline-none transition-colors bg-transparent border border-blue-600 text-blue-600 hover:bg-blue-50"
        >
          Outline Button
        </button>
      </div>
    
      <div class="mt-8 p-4 bg-gray-100 rounded">
        <p class="font-medium">Count: <%= @count %></p>
      </div>
    </div>
    """
  end
  
  def handle_event("handle_event", _params, socket) do
    IO.puts("Test component event received")
    new_count = socket.assigns.count + 1
    {:noreply, assign(socket, count: new_count)}
  end
end 
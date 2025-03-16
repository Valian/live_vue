defmodule LiveVueUIExampleWeb.HomeLive do
  use Phoenix.LiveView
  import LiveVueUI.Components

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Home")}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg p-6">
      <div class="mb-8">
        <h2 class="text-2xl font-semibold mb-4">Welcome to LiveVue UI Example</h2>
        <p class="text-gray-700 mb-4">
          This is a showcase of Vue.js components integrated with Phoenix LiveView using the LiveVue library.
        </p>
        <p class="text-gray-700 mb-4">
          Browse through the examples using the navigation links above.
        </p>
      </div>

      <div class="mb-8">
        <h2 class="text-xl font-semibold mb-4">Features</h2>
        <ul class="list-disc pl-6 space-y-2 text-gray-700">
          <li>Server-side rendering of Vue components</li>
          <li>Interactive components with LiveView integration</li>
          <li>Seamless state management between LiveView and Vue</li>
          <li>Beautiful UI components built with TailwindCSS</li>
          <li>Easy to use and extend</li>
        </ul>
      </div>

      <div class="flex flex-wrap gap-4 mt-8">
        <.button phx-click="nothing">Get Started</.button>
        <.link navigate="/buttons" class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
          Browse Components
        </.link>
      </div>
    </div>
    """
  end
end 
defmodule LiveVueExamplesWeb.LiveHome do
  use LiveVueExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto">
      <div class="flex justify-between gap-4 items-center">
        <div>
          <h1 class="text-6xl font-bold leading-normal text-[#FD4F00]">LiveVue</h1>
          <h2 class="text-2xl font-medium text-slate-200/60 leading-loose mt-4">
            End-to-end reactivity with LiveView and Vue
          </h2>
          <div class="flex gap-4 mt-8">
            <a
              href="https://github.com/Valian/live_vue"
              class="px-5 py-2 rounded-full bg-orange-700 hover:bg-orange-600 font-bold text-sm"
            >
              Get Started
            </a>
            <a href={~p"/dead"} class="block px-5 py-2 rounded-full bg-gray-700 hover:bg-gray-500 font-bold text-sm">
              View Examples
            </a>
          </div>
        </div>
        <div class="relative group mr-32 mb-4">
          <div>
            <div class="absolute -left-10 right-10 -top-10 bottom-10 bg-green-300/30 group-hover:bg-green-300/50 rounded-full duration-500 transition blur-2xl" />
            <img src={~p"/images/vue-logo.svg"} class="relative w-full drop-shadow-lg" />
          </div>
          <div class="w-full h-full absolute top-16 left-32">
            <div class="absolute inset-0 bottom-10 bg-[#FD4F00]/30 group-hover:bg-[#FD4F00]/20 duration-500 transition rounded-full blur-xl rotate-[30deg]" />
            <img src={~p"/images/phoenix-logo.svg"} class="relative w-full drop-shadow-lg" />
          </div>
        </div>
      </div>
      <div class="mt-12  grid grid-cols-4 gap-6">
        <div class="rounded-lg bg-gray-700 p-4 h-32">Work in progress</div>
        <div class="rounded-lg bg-gray-700 p-4 h-32">Work in progress</div>
        <div class="rounded-lg bg-gray-700 p-4 h-32">Work in progress</div>
        <div class="rounded-lg bg-gray-700 p-4 h-32">Work in progress</div>
        <div class="rounded-lg bg-gray-700 p-4 h-32">Work in progress</div>
        <div class="rounded-lg bg-gray-700 p-4 h-32">Work in progress</div>
        <div class="rounded-lg bg-gray-700 p-4 h-32">Work in progress</div>
        <div class="rounded-lg bg-gray-700 p-4 h-32">Work in progress</div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket = assign(socket, :container_class, "max-w-6xl")
    {:ok, socket, layout: false}
  end
end

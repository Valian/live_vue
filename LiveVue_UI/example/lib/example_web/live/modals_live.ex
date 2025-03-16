defmodule LiveVueUIExampleWeb.ModalsLive do
  use Phoenix.LiveView, layout: {LiveVueUIExampleWeb.Layouts, :root}
  import LiveVueUI.Components
  alias Phoenix.LiveView.JS

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Modal Examples",
       basic_modal_open: false,
       confirmation_modal_open: false,
       form_modal_open: false,
       large_modal_open: false,
       form_data: %{name: "", email: ""}
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg p-6">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Basic Modal -->
        <div class="bg-gray-50 p-6 rounded-lg">
          <h2 class="text-xl font-semibold mb-4">Basic Modal</h2>
          <p class="mb-4">A simple modal with a title and content.</p>
          <.button phx-click={show_modal("basic")}>Open Basic Modal</.button>

          <.modal title="Basic Modal" open={@basic_modal_open} on_close="close_basic_modal">
            <p>This is a basic modal with some content.</p>
            <p class="mt-4">You can close it by clicking the X button, clicking outside, or pressing ESC.</p>
          </.modal>
        </div>

        <!-- Confirmation Modal -->
        <div class="bg-gray-50 p-6 rounded-lg">
          <h2 class="text-xl font-semibold mb-4">Confirmation Modal</h2>
          <p class="mb-4">A modal for confirming actions with custom buttons.</p>
          <.button variant={:secondary} phx-click={show_modal("confirmation")}>
            Open Confirmation Modal
          </.button>

          <.modal
            title="Confirm Action"
            open={@confirmation_modal_open}
            on_close="close_confirmation_modal"
          >
            <p>Are you sure you want to perform this action?</p>
            <p class="mt-2 text-gray-600">This action cannot be undone.</p>

            <:footer>
              <.button
                variant={:ghost}
                phx-click="close_confirmation_modal"
              >
                Cancel
              </.button>
              <.button
                phx-click="confirm_action"
              >
                Confirm
              </.button>
            </:footer>
          </.modal>
        </div>

        <!-- Form Modal -->
        <div class="bg-gray-50 p-6 rounded-lg">
          <h2 class="text-xl font-semibold mb-4">Form Modal</h2>
          <p class="mb-4">A modal containing a form.</p>
          <.button variant={:outline} phx-click={show_modal("form")}>Open Form Modal</.button>

          <.modal
            title="Contact Form"
            open={@form_modal_open}
            on_close="close_form_modal"
          >
            <form phx-submit="submit_form" class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
                <input
                  type="text"
                  name="name"
                  value={@form_data.name}
                  phx-change="form_change"
                  placeholder="Enter your name"
                  class="w-full p-2 border border-gray-300 rounded-md"
                  required
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input
                  type="email"
                  name="email"
                  value={@form_data.email}
                  phx-change="form_change"
                  placeholder="Enter your email"
                  class="w-full p-2 border border-gray-300 rounded-md"
                  required
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Message</label>
                <textarea
                  name="message"
                  phx-change="form_change"
                  placeholder="Enter your message"
                  class="w-full p-2 border border-gray-300 rounded-md"
                  rows="3"
                  required
                ></textarea>
              </div>
              <div class="flex justify-end space-x-2">
                <.button
                  type="button"
                  variant={:ghost}
                  phx-click="close_form_modal"
                >
                  Cancel
                </.button>
                <.button type="submit">
                  Submit
                </.button>
              </div>
            </form>
          </.modal>
        </div>

        <!-- Large Modal -->
        <div class="bg-gray-50 p-6 rounded-lg">
          <h2 class="text-xl font-semibold mb-4">Large Modal</h2>
          <p class="mb-4">A larger modal with more content and custom width.</p>
          <.button variant={:ghost} phx-click={show_modal("large")}>Open Large Modal</.button>

          <.modal
            title="Large Modal"
            open={@large_modal_open}
            on_close="close_large_modal"
            max_width="2xl"
          >
            <div class="space-y-4">
              <p>This is a larger modal with more content.</p>
              <p>
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam euismod, nisl eget
                ultricies aliquam, quam libero ultricies nunc, vitae aliquam nisl nunc eu nisl.
                Nulla facilisi. Sed euismod, nisl eget ultricies aliquam, quam libero ultricies
                nunc, vitae aliquam nisl nunc eu nisl.
              </p>
              <p>
                Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis
                egestas. Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit amet,
                ante. Donec eu libero sit amet quam egestas semper. Aenean ultricies mi vitae est.
                Mauris placerat eleifend leo.
              </p>
            </div>
          </.modal>
        </div>
      </div>
    </div>
    """
  end

  def show_modal(modal) do
    JS.push("show_modal", value: %{modal: modal})
  end

  def handle_event("show_modal", %{"modal" => "basic"}, socket) do
    {:noreply, assign(socket, basic_modal_open: true)}
  end

  def handle_event("show_modal", %{"modal" => "confirmation"}, socket) do
    {:noreply, assign(socket, confirmation_modal_open: true)}
  end

  def handle_event("show_modal", %{"modal" => "form"}, socket) do
    {:noreply, assign(socket, form_modal_open: true)}
  end

  def handle_event("show_modal", %{"modal" => "large"}, socket) do
    {:noreply, assign(socket, large_modal_open: true)}
  end

  def handle_event("close_basic_modal", _, socket) do
    {:noreply, assign(socket, basic_modal_open: false)}
  end

  def handle_event("close_confirmation_modal", _, socket) do
    {:noreply, assign(socket, confirmation_modal_open: false)}
  end

  def handle_event("close_form_modal", _, socket) do
    {:noreply, assign(socket, form_modal_open: false)}
  end

  def handle_event("close_large_modal", _, socket) do
    {:noreply, assign(socket, large_modal_open: false)}
  end

  def handle_event("confirm_action", _, socket) do
    # Here you would handle the confirmed action
    socket = 
      socket
      |> assign(confirmation_modal_open: false)
      |> put_flash(:info, "Action confirmed successfully!")

    {:noreply, socket}
  end

  def handle_event("form_change", params, socket) do
    # Update form data based on changed fields
    form_data = Map.merge(socket.assigns.form_data, Map.take(params, ["name", "email", "message"]))
    {:noreply, assign(socket, form_data: form_data)}
  end

  def handle_event("submit_form", _params, socket) do
    # Here you would handle the form submission
    socket = 
      socket
      |> assign(form_modal_open: false)
      |> put_flash(:info, "Form submitted successfully!")

    {:noreply, socket}
  end
end 
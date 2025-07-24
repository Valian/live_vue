defmodule LiveVueExamplesWeb.LiveUploadVue do
  use LiveVueExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header>LiveView File Upload with Vue Component</.header>
    <.vue
      upload={@uploads.avatar}
      uploaded-files={@uploaded_files}
      v-component="FileUpload"
      v-socket={@socket}
    />
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg .png .gif .pdf .txt .doc .docx),
        max_entries: 5,
        max_file_size: 10_000_000 # 10MB
     )}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        # Read the file content and store metadata in the socket
        file_content = File.read!(path)
        file_info = %{
          name: entry.client_name,
          size: byte_size(file_content),
          type: entry.client_type,
          # content: file_content
        }

        # Clean up the temporary file
        File.rm(path)

        {:ok, file_info}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end
end

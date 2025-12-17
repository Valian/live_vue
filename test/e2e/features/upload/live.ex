defmodule LiveVue.E2E.UploadTestLive do
  @moduledoc false
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div>
      <h1>Upload Test</h1>
      <div id="upload-mode">Mode: {@upload_mode}</div>
      <div id="uploaded-count">Uploaded files: {length(@uploaded_files)}</div>

      <LiveVue.vue
        id="upload-component"
        upload={@uploads.test_files}
        uploadedFiles={@uploaded_files}
        v-component="upload-test"
        v-socket={@socket}
      />
    </div>
    """
  end

  def mount(%{"mode" => mode}, _session, socket) do
    auto_upload = mode == "auto"

    {:ok,
     socket
     |> assign(:upload_mode, mode)
     |> assign(:uploaded_files, [])
     |> allow_upload(:test_files,
       accept: ~w(.txt .pdf .jpg .png),
       max_entries: 3,
       # 1MB
       max_file_size: 1_000_000,
       auto_upload: auto_upload
     )}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :test_files, ref)}
  end

  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :test_files, fn %{path: path}, entry ->
        # Simulate processing the file
        file_info = %{
          name: entry.client_name,
          size: entry.client_size,
          type: entry.client_type
        }

        # Clean up the temporary file
        File.rm(path)

        {:ok, file_info}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end
end

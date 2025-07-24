defmodule LiveVueExamplesWeb.LiveUpload do
  use LiveVueExamplesWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header>File Upload Example</.header>

    <div class="max-w-2xl mx-auto p-6">
      <form phx-submit="save" phx-change="validate" class="space-y-6">
        <div class="space-y-2">
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
            Upload Files
          </label>

          <div class="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 dark:border-gray-600 border-dashed rounded-md"
               phx-drop-target={@uploads.avatar.ref}>
            <div class="space-y-4 text-center">
              <.live_file_input upload={@uploads.avatar} class="sr-only" id="avatar-upload" />

              <div class="flex flex-col items-center space-y-2">
                <label for={@uploads.avatar.ref} class="relative cursor-pointer bg-indigo-600 dark:bg-indigo-500 text-white rounded-lg font-medium hover:bg-indigo-700 dark:hover:bg-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-indigo-500 px-6 py-3 shadow-sm transition-colors">
                  <span>Choose Files</span>
                </label>
                <p class="text-sm text-gray-600 dark:text-gray-400">or drag and drop files here</p>
              </div>

              <p class="text-xs text-gray-500 dark:text-gray-400">PNG, JPG, GIF, PDF, TXT up to 10MB</p>
            </div>
          </div>
        </div>

        <div class="space-y-4">
          <pre><%= inspect(@uploads.avatar.entries) %></pre>
          <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100" :if={@uploads.avatar.entries != []}>Ready to upload</h3>

          <%= for entry <- @uploads.avatar.entries do %>
            <div class="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800">
              <div class="flex items-center space-x-3">
                <div class="flex-shrink-0">
                  <%= if entry.client_type =~ "image" do %>
                    <.live_img_preview entry={entry} class="h-12 w-12 rounded-lg object-cover" />
                  <% else %>
                    <div class="h-12 w-12 bg-gray-100 dark:bg-gray-700 rounded-lg flex items-center justify-center">
                      <svg class="h-6 w-6 text-gray-400 dark:text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                      </svg>
                    </div>
                  <% end %>
                </div>

                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">
                    <%= entry.client_name %>
                  </p>
                  <p class="text-sm text-gray-500 dark:text-gray-400">
                    <%= format_file_size(entry.client_size) %>
                  </p>
                </div>
              </div>

              <div class="flex items-center space-x-2">
                <%= if entry.progress do %>
                  <div class="text-sm text-gray-500 dark:text-gray-400">
                    <%= entry.progress %>%
                  </div>
                <% end %>

                <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref}
                        class="text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-300">
                  <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            </div>

            <%= for err <- upload_errors(@uploads.avatar, entry) do %>
              <div class="text-sm text-red-600 dark:text-red-400">
                <%= error_to_string(err) %>
              </div>
            <% end %>
          <% end %>

          <%= for err <- upload_errors(@uploads.avatar) do %>
            <div class="text-sm text-red-600 dark:text-red-400">
              <%= error_to_string(err) %>
            </div>
          <% end %>
        </div>

        <div class="flex justify-end">
          <button type="submit" class="px-4 py-2 bg-indigo-600 dark:bg-indigo-500 text-white rounded-md hover:bg-indigo-700 dark:hover:bg-indigo-600 focus:outline-none focus:ring-2 focus:ring-indigo-500">
            Upload Files
          </button>
        </div>
      </form>

      <%= if @uploaded_files != [] do %>
        <div class="mt-8 space-y-4">
          <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100">Successfully Uploaded Files</h3>
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <%= for file <- @uploaded_files do %>
              <div class="bg-gray-50 dark:bg-gray-800 p-4 rounded-lg border border-gray-200 dark:border-gray-700">
                <p class="text-sm font-medium text-gray-900 dark:text-gray-100"><%= file.name %></p>
                <p class="text-sm text-gray-500 dark:text-gray-400"><%= format_file_size(file.size) %></p>
                <p class="text-sm text-gray-500 dark:text-gray-400"><%= file.type %></p>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
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

  def handle_event("validate", params, socket) do
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
          content: file_content
        }

        # Clean up the temporary file
        File.rm(path)

        {:ok, file_info}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end

  defp error_to_string(:too_large), do: "File is too large"
  defp error_to_string(:too_many_files), do: "Too many files"
  defp error_to_string(:not_accepted), do: "Unacceptable file type"
  defp error_to_string(_), do: "Invalid file"

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{div(bytes, 1024)} KB"
  defp format_file_size(bytes) when bytes < 1024 * 1024 * 1024, do: "#{div(bytes, 1024 * 1024)} MB"
  defp format_file_size(bytes), do: "#{div(bytes, 1024 * 1024 * 1024)} GB"
end

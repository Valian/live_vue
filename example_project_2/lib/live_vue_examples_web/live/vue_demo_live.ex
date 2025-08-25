defmodule LiveVueExamplesWeb.VueDemoLive do
  use LiveVueExamplesWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.vue
        todos={@todos}
        form={@form}
        v-component="VueDemo"
        v-socket={@socket}
      />
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:todos, [
        %{id: 1, text: "Learn LiveVue basics", completed: true},
        %{id: 2, text: "Build an interactive component", completed: false},
        %{id: 3, text: "Deploy to production", completed: false}
      ])
      |> assign(:next_id, 4)
      |> assign(:form, add_todo_form(%{text: ""}))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_todo", %{"todo" => params}, socket) do
    {:noreply, assign(socket, :form, add_todo_form(params))}
  end

  @impl true
  def handle_event("add_todo", %{"todo" => params}, socket) do
    changeset = add_todo_changeset(params, socket.assigns.next_id)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, new_todo} ->
        socket =
          socket
          |> assign(:todos, socket.assigns.todos ++ [new_todo])
          |> assign(:next_id, socket.assigns.next_id + 1)
          |> assign(:form, add_todo_form(%{text: ""}))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :todo))}
    end
  end

  @impl true
  def handle_event("toggle_todo", %{"id" => id}, socket) do
    todos =
      Enum.map(socket.assigns.todos, fn todo ->
        if todo.id == id, do: %{todo | completed: !todo.completed}, else: todo
      end)

    {:noreply, assign(socket, :todos, todos)}
  end

  @impl true
  def handle_event("delete_todo", %{"id" => id}, socket) do
    todos = Enum.reject(socket.assigns.todos, fn todo -> todo.id == id end)
    {:noreply, assign(socket, :todos, todos)}
  end

  @impl true
  def handle_event("clear_completed", _params, socket) do
    todos = Enum.reject(socket.assigns.todos, fn todo -> todo.completed end)
    {:noreply, assign(socket, :todos, todos)}
  end

  defp add_todo_changeset(params, id \\ nil) do
    data = %{text: "", id: id, completed: false}
    types = %{text: :string}

    {data, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required([:text])
    |> Ecto.Changeset.validate_length(:text, min: 8, max: 50)
  end

  defp add_todo_form(params) do
    params
    |> add_todo_changeset()
    |> Map.put(:action, :validate)
    |> to_form(as: :todo)
  end
end

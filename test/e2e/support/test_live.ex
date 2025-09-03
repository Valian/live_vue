defmodule LiveVue.E2E.TestLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :counter, 0)}
  end

  def handle_event("increment", %{"value" => value}, socket) do
    {:noreply, assign(socket, :counter, socket.assigns.counter + value)}
  end

  def render(assigns) do
    ~H"""
    <LiveVue.vue count={@counter} v-component="counter" v-socket={@socket} />
    """
  end
end

defmodule LiveVue.E2E.NavigationLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(params, _session, socket) do
    {:ok, assign(socket, params: params, query_params: %{})}
  end

  def handle_params(params, uri, socket) do
    query_params = URI.parse(uri).query
    parsed_query = if query_params, do: URI.decode_query(query_params), else: %{}
    {:noreply, assign(socket, params: params, query_params: parsed_query)}
  end

  def render(assigns) do
    ~H"""
    <div id="navigation-test">
      <LiveVue.vue params={@params} query_params={@query_params} v-component="navigation" v-socket={@socket} />
    </div>
    """
  end
end

defmodule LiveVue.E2E.EventLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, message: "", event_count: 0)}
  end

  def handle_event("send_notification", %{"message" => message}, socket) do
    # Send a server event to the Vue component
    send(self(), {:broadcast_event, "notification", %{message: message, timestamp: :os.system_time(:millisecond)}})
    {:noreply, assign(socket, message: message, event_count: socket.assigns.event_count + 1)}
  end

  def handle_event("send_custom_event", %{"data" => data}, socket) do
    # Send a custom event with structured data
    send(self(), {:broadcast_event, "custom_event", %{data: data, count: socket.assigns.event_count + 1}})
    {:noreply, assign(socket, event_count: socket.assigns.event_count + 1)}
  end

  def handle_info({:broadcast_event, event_name, payload}, socket) do
    # Push the event to the client
    {:noreply, push_event(socket, event_name, payload)}
  end

  def render(assigns) do
    ~H"""
    <div id="event-test">
      <div id="message-display">Message: {@message}</div>
      <div id="event-count">Event Count: {@event_count}</div>
      <LiveVue.vue message={@message} event_count={@event_count} v-component="event_test" v-socket={@socket} />
    </div>
    """
  end
end

defmodule LiveVue.E2E.StreamLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    # Initialize with some sample items
    items = [
      %{id: 1, name: "Item 1", description: "First item"},
      %{id: 2, name: "Item 2", description: "Second item"},
      %{id: 3, name: "Item 3", description: "Third item"}
    ]

    socket =
      socket
      |> stream_configure(:items, dom_id: &"songs-#{&1.id}")
      |> stream(:items, items)
      |> assign(:next_id, 4)

    {:ok, socket}
  end

  def handle_event("add_item", %{"name" => name, "description" => description}, socket) do
    new_item = %{
      id: socket.assigns.next_id,
      name: name,
      description: description
    }

    socket =
      socket
      |> stream_insert(:items, new_item)
      |> assign(:next_id, socket.assigns.next_id + 1)

    {:noreply, socket}
  end

  def handle_event("remove_item", %{"id" => id}, socket) do
    {:noreply, stream_delete_by_dom_id(socket, :items, "songs-#{id}")}
  end

  def handle_event("clear_stream", _params, socket) do
    # Reset the stream with empty list
    socket =
      socket
      |> stream(:items, [], reset: true)
      |> assign(:next_id, 1)

    {:noreply, socket}
  end

  def handle_event("reset_stream", _params, socket) do
    # Reset with initial items
    items = [
      %{id: 1, name: "Item 1", description: "First item"},
      %{id: 2, name: "Item 2", description: "Second item"},
      %{id: 3, name: "Item 3", description: "Third item"}
    ]

    socket =
      socket
      |> stream(:items, items, at: 0, reset: true)
      |> assign(:next_id, 4)

    {:noreply, socket}
  end

  def handle_event("add_multiple_start", _params, socket) do
    # Add multiple items at the start with positive limit (keep first 5 items)
    new_items = [
      %{id: socket.assigns.next_id, name: "Start Item A", description: "Added at start A"},
      %{id: socket.assigns.next_id + 1, name: "Start Item B", description: "Added at start B"},
      %{id: socket.assigns.next_id + 2, name: "Start Item C", description: "Added at start C"}
    ]

    socket =
      socket
      |> stream(:items, new_items, at: 0, limit: 5)
      |> assign(:next_id, socket.assigns.next_id + 3)

    {:noreply, socket}
  end

  def handle_event("add_multiple_end", _params, socket) do
    # Add multiple items at the end with negative limit (keep last 5 items)
    new_items = [
      %{id: socket.assigns.next_id, name: "End Item X", description: "Added at end X"},
      %{id: socket.assigns.next_id + 1, name: "End Item Y", description: "Added at end Y"},
      %{id: socket.assigns.next_id + 2, name: "End Item Z", description: "Added at end Z"}
    ]

    socket =
      socket
      |> stream(:items, new_items, at: -1, limit: -5)
      |> assign(:next_id, socket.assigns.next_id + 3)

    {:noreply, socket}
  end

  def handle_event("add_with_positive_limit", %{"limit" => limit_str}, socket) do
    limit = String.to_integer(limit_str)

    new_item = %{
      id: socket.assigns.next_id,
      name: "Limited Item +#{limit}",
      description: "Added with positive limit #{limit}"
    }

    socket =
      socket
      |> stream_insert(:items, new_item, at: 0, limit: limit)
      |> assign(:next_id, socket.assigns.next_id + 1)

    {:noreply, socket}
  end

  def handle_event("add_with_negative_limit", %{"limit" => limit_str}, socket) do
    # Make it negative
    limit = String.to_integer(limit_str) * -1

    new_item = %{
      id: socket.assigns.next_id,
      name: "Limited Item #{limit}",
      description: "Added with negative limit #{limit}"
    }

    socket =
      socket
      |> stream_insert(:items, new_item, limit: limit)
      |> assign(:next_id, socket.assigns.next_id + 1)

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div id="stream-test">
      <LiveVue.vue items={@streams.items} v-component="stream_test" v-socket={@socket} />
    </div>
    """
  end
end

defmodule LiveVue.E2E.FormTestLive do
  @moduledoc false
  use Phoenix.LiveView

  import Ecto.Changeset

  defmodule Profile do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @derive LiveVue.Encoder
    @primary_key false
    embedded_schema do
      field(:bio, :string)
      field(:skills, {:array, :string}, default: [])
    end

    def changeset(profile, attrs) do
      profile
      |> cast(attrs, [:bio, :skills], empty_values: [])
      |> validate_length(:bio, min: 10, max: 200, message: "must be between 10 and 200 characters")
      |> validate_skills()
    end

    defp validate_skills(changeset) do
      case get_field(changeset, :skills) do
        nil ->
          changeset

        [] ->
          changeset

        skills ->
          # Check if all skills are non-empty strings
          invalid_skills =
            Enum.filter(skills, fn skill ->
              !is_binary(skill) || String.trim(skill) == ""
            end)

          if Enum.empty?(invalid_skills) do
            changeset
          else
            add_error(changeset, :skills, "cannot contain empty values")
          end
      end
    end
  end

  defmodule Item do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @derive LiveVue.Encoder
    @primary_key false
    embedded_schema do
      field(:title, :string)
      field(:tags, {:array, :string}, default: [])
    end

    def changeset(item, attrs) do
      item
      |> cast(attrs, [:title, :tags])
      |> validate_required([:title])
      |> validate_length(:title, min: 3, max: 100)
      |> validate_tags()
    end

    defp validate_tags(changeset) do
      Ecto.Changeset.validate_change(changeset, :tags, fn :tags, tags ->
        if Enum.any?(tags, fn tag -> !is_binary(tag) || String.length(String.trim(tag)) < 3 end) do
          [tags: "must be at least 3 characters long"]
        else
          []
        end
      end)
    end
  end

  defmodule TestForm do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @derive LiveVue.Encoder
    @primary_key false
    embedded_schema do
      field(:name, :string)
      field(:email, :string)
      field(:age, :integer)
      field(:acceptTerms, :boolean, default: false)
      field(:newsletter, :boolean, default: false)
      field(:preferences, {:array, :string}, default: [])
      embeds_one(:profile, Profile)
      embeds_many(:items, Item)
    end

    def changeset(form, attrs) do
      form
      |> cast(attrs, [:name, :email, :age, :acceptTerms, :newsletter, :preferences])
      |> validate_required([:name, :email], message: "is required")
      |> validate_length(:name, min: 2, max: 50)
      |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email address")
      |> validate_number(:age, greater_than: 0, less_than: 150, message: "must be between 1 and 149")
      |> validate_acceptance(:acceptTerms, message: "must be accepted to proceed")
      |> validate_preferences()
      |> cast_embed(:profile)
      |> cast_embed(:items)
    end

    defp validate_preferences(changeset) do
      case get_field(changeset, :preferences) do
        nil ->
          changeset

        [] ->
          changeset

        preferences ->
          valid_preferences = ["email", "sms", "push"]
          invalid_preferences = Enum.filter(preferences, fn pref -> pref not in valid_preferences end)

          if Enum.empty?(invalid_preferences) do
            changeset
          else
            add_error(changeset, :preferences, "contains invalid options: #{Enum.join(invalid_preferences, ", ")}")
          end
      end
    end
  end

  def mount(_params, _session, socket) do
    form = %TestForm{} |> TestForm.changeset(%{}) |> to_form(as: :test_form)
    {:ok, assign(socket, :form, form)}
  end

  def handle_event("validate", %{"test_form" => form_params}, socket) do
    form =
      %TestForm{}
      |> TestForm.changeset(form_params)
      |> Map.put(:action, :validate)
      |> to_form(as: :test_form)

    LiveVue.Encoder.encode(form)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"test_form" => form_params}, socket) do
    changeset = TestForm.changeset(%TestForm{}, form_params)

    if changeset.valid? do
      case Ecto.Changeset.apply_action(changeset, :insert) do
        {:ok, data} ->
          IO.puts("\n=== FORM SUBMITTED SUCCESSFULLY ===")
          IO.inspect(data, pretty: true, limit: :infinity)
          IO.puts("\n====================================")

          form = %TestForm{} |> TestForm.changeset(%{}) |> to_form(as: :test_form)

          {:reply, %{reset: true},
           socket
           |> put_flash(:info, "Form submitted successfully!")
           |> assign(:form, form)}

        {:error, changeset} ->
          form = to_form(changeset, as: :test_form)
          {:noreply, assign(socket, :form, form)}
      end
    else
      form = to_form(%{changeset | action: :insert}, as: :test_form)
      {:noreply, assign(socket, :form, form)}
    end
  end

  def render(assigns) do
    ~H"""
    <div id="form-test">
      <LiveVue.vue form={@form} v-component="form_test" v-socket={@socket} />
    </div>
    """
  end
end

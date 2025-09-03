defmodule LiveVueExamplesWeb.LiveForm do
  use LiveVueExamplesWeb, :live_view
  import Ecto.Changeset

  defmodule Owner do
    use Ecto.Schema
    import Ecto.Changeset

    @derive LiveVue.Encoder
    @primary_key false
    embedded_schema do
      field :name, :string
      field :email, :string
      field :role, :string, default: "project_manager"
    end

    def changeset(owner, attrs) do
      owner
      |> cast(attrs, [:name, :email, :role])
      |> validate_required([:name, :email, :role])
      |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
      |> validate_inclusion(:role, ["project_manager", "tech_lead", "product_owner", "team_lead"])
    end
  end

  defmodule Assignee do
    use Ecto.Schema
    import Ecto.Changeset

    @derive LiveVue.Encoder
    @primary_key false
    embedded_schema do
      field :member_id, :string
      field :role, :string, default: "contributor"
    end

    def changeset(assignee, attrs) do
      assignee
      |> cast(attrs, [:member_id, :role])
      |> validate_required([:member_id, :role])
      |> validate_inclusion(:role, ["contributor", "reviewer", "lead"])
    end
  end

  defmodule Task do
    use Ecto.Schema
    import Ecto.Changeset

    @derive LiveVue.Encoder
    @primary_key false
    embedded_schema do
      field :title, :string
      field :description, :string
      field :priority, :string, default: "medium"
      embeds_many :assignees, Assignee
    end

    def changeset(task, attrs) do
      task
      |> cast(attrs, [:title, :description, :priority])
      |> validate_required([:title, :description, :priority])
      |> validate_length(:title, min: 3, max: 100)
      |> validate_inclusion(:priority, ["low", "medium", "high", "urgent"])
      |> cast_embed(:assignees)
    end
  end

  defmodule TeamMember do
    use Ecto.Schema
    import Ecto.Changeset

    @derive LiveVue.Encoder
    @primary_key false
    embedded_schema do
      field :name, :string
      field :email, :string
      field :skills, {:array, :string}, default: []
    end

    def changeset(team_member, attrs) do
      team_member
      |> cast(attrs, [:name, :email, :skills])
      |> validate_required([:name, :email])
      |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
      |> validate_skills()
    end

    defp validate_skills(changeset) do
      case get_field(changeset, :skills) do
        nil -> changeset
        [] -> changeset
        skills ->
          # Check if all skills are non-empty strings
          invalid_skills = Enum.filter(skills, fn skill ->
            !is_binary(skill) || String.trim(skill) == ""
          end)

          if Enum.empty?(invalid_skills) do
            changeset
          else
            add_error(changeset, :skills, "cannot be empty")
          end
      end
    end
  end

  defmodule Project do
    use Ecto.Schema
    import Ecto.Changeset

    @derive LiveVue.Encoder
    @primary_key false
    embedded_schema do
      field :name, :string
      field :description, :string
      field :status, :string, default: "planning"
      field :notifications, {:array, :string}, default: []
      field :is_public, :boolean, default: false
      embeds_one :owner, Owner
      embeds_many :team_members, TeamMember
      embeds_many :tasks, Task
    end

    def changeset(project, attrs) do
      project
      |> cast(attrs, [:name, :description, :status, :is_public, :notifications])
      |> validate_required([:name, :description, :status])
      |> validate_length(:name, min: 3, max: 100)
      |> validate_length(:description, min: 10, max: 500)
      |> validate_inclusion(:status, ["planning", "active", "on_hold", "completed"])
      |> cast_embed(:owner, required: true)
      |> cast_embed(:team_members)
      |> cast_embed(:tasks)
    end
  end

  def render(assigns) do
    ~H"""
    <.header>Complex Form with Nested Arrays</.header>
    <.FormExample form={@form} v-socket={@socket} />
    """
  end

  def mount(_params, _session, socket) do
    form = Project.changeset(%Project{}, %{}) |> to_form(as: :project)
    {:ok, assign(socket, :form, form)}
  end

  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset = %Project{}
    |> Project.changeset(project_params)
    |> Map.put(:action, :validate)
    form = to_form(changeset, as: :project)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"project" => project_params}, socket) do
    changeset = Project.changeset(%Project{}, project_params)

    # In a real app, you would save the data here
    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, data} ->
        IO.puts("\n=== PROJECT SUBMITTED SUCCESSFULLY ===")
        IO.inspect(data, pretty: true, limit: :infinity)
        IO.puts("\n=====================================")

        socket = socket
        |> put_flash(:info, "Project created successfully!")
        |> assign(:form, Project.changeset(%Project{}, %{}) |> to_form(as: :project))

        {:reply, %{reset: true}, socket}

      {:error, changeset} ->
        form = changeset |> to_form(as: :project)

        socket = socket
        |> put_flash(:error, "Project creation failed, check errors")
        |> assign(:form, form)

        {:noreply, socket}
    end
  end

end

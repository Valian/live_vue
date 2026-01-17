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
      <LiveVue.vue form={@form} v-component="form_test" />
    </div>
    """
  end
end

defmodule LiveVueExamplesWeb.LiveForm do
  use LiveVueExamplesWeb, :live_view
  import Ecto.Changeset

  def render(assigns) do
    ~H"""
    <.header>Form example - TODO</.header>
    <.FormExample form={@form} v-socket={@socket} />
    """
  end

  def mount(_params, _session, socket) do
    form = user_changeset() |> to_form(as: :user)
    {:ok, assign(socket, :form, form)}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    form =
      user_params
      |> user_changeset()
      |> Map.put(:action, :validate)
      |> to_form(as: :user)

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("submit", %{"user" => user_params}, socket) do
    changeset = user_changeset(user_params)

    if changeset.valid? do
      # In a real app, you would save the data here
      data = Ecto.Changeset.apply_action(changeset, :insert)
      dbg("Saved user: #{inspect(data)}")

      {:noreply,
       socket
       |> assign(:form, user_changeset() |> to_form(as: :user))}
    else
      form =
        %{changeset | action: :insert}
        |> to_form(as: :user)

      {:noreply, assign(socket, :form, form)}
    end
  end

  def user_changeset(params \\ %{}) do
    data = %{
      email: nil,
      first_name: nil,
      last_name: nil,
      country: nil
    }

    types = %{
      email: :string,
      first_name: :string,
      last_name: :string,
      country: :string
    }

    {data, types}
    |> cast(params, Map.keys(types))
    |> validate_required([:email, :first_name, :last_name, :country])
    |> validate_format(:email, ~r/@/)
    |> validate_inclusion(:country, ["USA", "Canada", "UK", "Germany", "France", "Japan"])
  end
end

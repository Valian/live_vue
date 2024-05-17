defmodule LiveVue.Slots do
  @moduledoc false

  import Phoenix.Component

  @doc false
  def rendered_slot_map(assigns) do
    for(
      {key, [%{__slot__: _}] = slot} <- assigns,
      into: %{},
      do:
        case(key) do
          :inner_block -> {:default, render(%{slot: slot})}
          slot_name -> {slot_name, render(%{slot: slot})}
        end
    )
  end

  @doc false
  def base_encode_64(assigns) do
    for {key, value} <- assigns, into: %{}, do: {key, Base.encode64(value)}
  end

  @doc false
  defp render(assigns) do
    ~H"""
    <%= if assigns[:slot] do %>
      <%= render_slot(@slot) %>
    <% end %>
    """
    |> Phoenix.HTML.Safe.to_iodata()
    |> List.to_string()
    |> String.trim()
  end
end

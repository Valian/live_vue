defmodule LiveVue.Slots do
  @moduledoc false

  import Phoenix.Component

  @doc false
  def rendered_slot_map(assigns) when assigns == %{}, do: %{}

  def rendered_slot_map(assigns) do
    for(
      {key, [%{__slot__: _}] = slot} <- assigns,
      into: %{},
      do:
        case(key) do
          # we raise here because :inner_block is always there and we want to avoid
          # it overriding the default slot content
          :default -> raise "Instead of using <:default> use <:inner_block> slot"
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
      {render_slot(@slot)}
    <% end %>
    """
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> String.trim()
  end
end

defmodule LiveVueUI.Components do
  @moduledoc """
  LiveVue UI components for use in Phoenix LiveView templates.
  
  This module provides a set of function components that wrap Vue components
  to provide a seamless integration with Phoenix LiveView.
  """
  
  use Phoenix.Component
  import LiveVue
  import LiveVue.Components
  alias Phoenix.LiveView.JS
  
  @doc """
  Renders a button component.
  
  ## Examples
  
      <.button>Click me</.button>
      <.button phx-click="do_something">Click me</.button>
  
  ## Options
  
    * `class` - Additional CSS classes to add to the button
    * `variant` - The button variant (`:primary`, `:secondary`, `:outline`, `:ghost`)
    * `size` - The button size (`:sm`, `:md`, `:lg`)
    * `disabled` - Whether the button is disabled
  """
  attr :class, :string, default: nil
  attr :variant, :atom, default: :primary, values: [:primary, :secondary, :outline, :ghost]
  attr :size, :atom, default: :md, values: [:sm, :md, :lg]
  attr :disabled, :boolean, default: false
  attr :rest, :global
  
  slot :inner_block, required: true
  
  def button(assigns) do
    ~H"""
    <.vue
      v-component="LiveVueUIButton"
      class={@class}
      variant={@variant}
      size={@size}
      disabled={@disabled}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.vue>
    """
  end
  
  @doc """
  Renders a modal component.
  
  ## Examples
  
      <.modal title="Hello">
        Modal content goes here.
      </.modal>
  
  ## Options
  
    * `title` - The modal title
    * `open` - Whether the modal is open (controlled mode)
    * `on_close` - JS command or event to execute when the modal is closed
    * `max_width` - Maximum width of the modal ("sm", "md", "lg", "xl", "2xl", "full")
  """
  attr :title, :string, required: true
  attr :open, :boolean, default: false
  attr :on_close, :any, default: nil
  attr :max_width, :string, default: "md", values: ["sm", "md", "lg", "xl", "2xl", "full"]
  attr :rest, :global
  
  slot :inner_block, required: true
  slot :footer, required: false
  
  def modal(assigns) do
    v_on_close = case assigns.on_close do
      %JS{} = js -> js
      event when is_binary(event) -> JS.push(event)
      nil -> nil
    end
    
    assigns = assign(assigns, :v_on_close, v_on_close)
    
    ~H"""
    <.vue
      v-component="LiveVueUIModal"
      title={@title}
      open={@open}
      max_width={@max_width}
      v-on:close={@v_on_close}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
      <:footer :if={@footer != []}>
        <%= render_slot(@footer) %>
      </:footer>
    </.vue>
    """
  end
end 
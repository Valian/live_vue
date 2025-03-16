ExUnit.start()

# Mock Phoenix.LiveView.JS for tests
defmodule Phoenix.LiveView.JS do
  def push(event, opts \\ []) do
    %__MODULE__{
      ops: [
        %{
          op: "push",
          event: event,
          opts: opts
        }
      ]
    }
  end
end

# Mock Phoenix.Component for tests
defmodule Phoenix.Component do
  defmacro __using__(_) do
    quote do
      import Phoenix.Component
    end
  end

  def assign(assigns, key, value) do
    Map.put(assigns, key, value)
  end
end

# Mock for the vue component
defmodule LiveVue.Component do
  def vue(assigns) do
    # Convert all assigns to HTML attributes for assertions
    attrs =
      assigns
      |> Map.drop([:__changed__, :inner_block])
      |> Enum.map(fn {k, v} -> "#{k}=\"#{v}\"" end)
      |> Enum.join(" ")

    ~s(<div #{attrs}>#{if Map.has_key?(assigns, :inner_block), do: Phoenix.LiveView.Rendered.get(assigns.inner_block), else: ""}</div>)
  end
end

# Mock for LiveVue
defmodule LiveVue do
  def version, do: "0.5.0"
end

# Import the mock for tests
defmodule LiveVueUI.Components do
  defmacro __using__(_) do
    quote do
      import LiveVueUI.Components
    end
  end

  defmacro vue(assigns) do
    quote do
      LiveVue.Component.vue(unquote(assigns))
    end
  end
end 
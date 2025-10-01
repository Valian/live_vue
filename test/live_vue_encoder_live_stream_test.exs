defmodule LiveVue.Encoder.LiveStreamTest do
  use ExUnit.Case

  alias LiveVue.Encoder

  defmodule TestUser do
    @moduledoc false

    defstruct [:id, :name, :age]

    defimpl Encoder do
      def encode(user, opts) do
        result = %{id: user.id, name: user.name}
        if opts[:encode_age], do: Map.put(result, :age, user.age), else: result
      end
    end
  end

  defmodule TestPost do
    @moduledoc false
    @derive Encoder
    defstruct [:id, :title, :content, :author_id]
  end
end

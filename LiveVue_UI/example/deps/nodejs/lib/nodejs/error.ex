defmodule NodeJS.Error do
  @moduledoc """
  Error when Node.js sends back an error.
  """

  defexception message: nil, stack: nil
end

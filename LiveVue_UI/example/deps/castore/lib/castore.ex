defmodule CAStore do
  @moduledoc """
  Functionality to retrieve the up-to-date CA certificate store.

  The only purpose of this library is to keep an up-to-date CA certificate store file.
  This is why this module only provides one function, `file_path/0`, to access the path of
  the CA certificate store file. You can then read this file and use its contents for your
  own purposes.
  """

  @doc """
  Returns the path to the CA certificate store PEM file.

  ## Examples

      CAStore.file_path()
      #=> /Users/me/castore/_build/dev/lib/castore/priv/cacerts.pem"

  """
  @spec file_path() :: Path.t()
  def file_path() do
    Application.app_dir(:castore, "priv/cacerts.pem")
  end
end

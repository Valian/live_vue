defmodule LiveVueExamplesWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use LiveVueExamplesWeb, :controller` and
  `use LiveVueExamplesWeb, :live_view`.
  """
  use LiveVueExamplesWeb, :html

  embed_templates "layouts/*"

  @env Mix.env() # remember value at compile time
  def dev_env?, do: @env == :dev
end

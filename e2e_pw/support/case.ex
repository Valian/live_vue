defmodule LiveVue.E2E.Case do
  @moduledoc """
  Case template of the browser suite: `Playwright.Case` (a pooled browser and a context and page per
  test, with the defaults of config/) and the suite's helpers.
  """
  use ExUnit.CaseTemplate

  using opts do
    quote do
      use Playwright.Case, unquote(opts)

      import LiveVue.E2E.Utils
    end
  end
end

defmodule LiveVue.E2E.Utils do
  @moduledoc "Helpers for the browser suite."

  alias Playwright.Expect
  alias Playwright.Locator
  alias Playwright.Page
  alias Playwright.Promise

  # Wait for LiveView to be ready and Vue components to be mounted
  def sync_lv(page) do
    # Use longer timeout for connection - websocket setup can take time under load
    connection_timeout = [timeout: 5000]

    promises = [
      Promise.async(fn ->
        Expect.to_be_visible!(Locator.first(Page.locator(page, ".phx-connected")), connection_timeout)
      end),
      Promise.async(fn -> Expect.to_have_count!(Page.locator(page, ".phx-change-loading"), 0) end),
      Promise.async(fn -> Expect.to_have_count!(Page.locator(page, ".phx-click-loading"), 0) end),
      Promise.async(fn -> Expect.to_have_count!(Page.locator(page, ".phx-submit-loading"), 0) end)
    ]

    Process.sleep(50)
    promises |> Promise.all() |> Promise.await!()
  end

  # Execute code inside LiveView process
  def eval_lv(page, code, selector \\ "[data-phx-main]") do
    Page.evaluate!(
      page,
      """
      ([code, selector]) => {
        return new Promise(resolve => {
          window.liveSocket.main.withinTargets(selector, (targetView, targetCtx) => {
            targetView.pushEvent(
              "event",
              document.body,
              targetCtx,
              "sandbox:eval",
              { value: code },
              {},
              ({ result, error }) => {
                if (error) {
                  throw new Error(error)
                }
                resolve(result)
              }
            )
          })
        })
      }
      """,
      [code, selector]
    )
  end
end

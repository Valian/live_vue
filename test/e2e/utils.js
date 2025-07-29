import { expect } from "@playwright/test"

// Wait for LiveView to be ready and Vue components to be mounted
export const syncLV = async page => {
  const promises = [
    expect(page.locator(".phx-connected").first()).toBeVisible(),
    expect(page.locator(".phx-change-loading")).toHaveCount(0),
    expect(page.locator(".phx-click-loading")).toHaveCount(0),
    expect(page.locator(".phx-submit-loading")).toHaveCount(0),
  ]
  return Promise.all(promises)
}

// Execute code inside LiveView process
export const evalLV = async (page, code, selector = "[data-phx-main]") =>
  await page.evaluate(
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
    },
    [code, selector]
  )

// Generate random string for test isolation
export const randomString = length => {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  let result = ""
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return result
}

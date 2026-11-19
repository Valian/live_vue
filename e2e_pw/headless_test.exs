defmodule LiveVue.E2E.HeadlessTest do
  use LiveVue.E2E.Case, async: true

  test "headless component exposes reactive props via useLiveVue(elementId)", %{page: page} do
    Page.goto!(page, "/headless")
    sync_lv(page)

    Expect.to_have_text!(Page.locator(page, "[data-pw-count]"), "0")
    Expect.to_have_text!(Page.locator(page, "[data-pw-label]"), "Hello")

    Locator.click!(Page.locator(page, "[data-pw-increment]"))
    sync_lv(page)
    Expect.to_have_text!(Page.locator(page, "[data-pw-count]"), "1")

    Locator.click!(Page.locator(page, "[data-pw-increment]"))
    sync_lv(page)
    Expect.to_have_text!(Page.locator(page, "[data-pw-count]"), "2")
  end

  test "headless component updates non-numeric props reactively", %{page: page} do
    Page.goto!(page, "/headless")
    sync_lv(page)

    Expect.to_have_text!(Page.locator(page, "[data-pw-label]"), "Hello")

    Locator.fill!(Page.locator(page, "[data-pw-label-input]"), "Updated")
    Locator.click!(Page.locator(page, "[data-pw-update-label]"))
    sync_lv(page)
    Expect.to_have_text!(Page.locator(page, "[data-pw-label]"), "Updated")
  end

  test "headless component renders no visible UI", %{page: page} do
    Page.goto!(page, "/headless")
    sync_lv(page)

    headless_el = Page.locator(page, "#data-source")
    Expect.to_be_attached!(headless_el)
    headless_el |> Expect.not_() |> Expect.to_have_attribute!("data-name")
    Expect.to_have_text!(headless_el, "")
  end
end

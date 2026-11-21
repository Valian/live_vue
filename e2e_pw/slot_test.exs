defmodule LiveVue.E2E.SlotTest do
  use LiveVue.E2E.Case, async: true

  defp slot(page, label) do
    page
    |> Page.locator(~s|[data-pw-label]:has-text("#{label}")|)
    |> Locator.locator("..")
    |> Locator.locator("[data-pw-slot]")
  end

  describe "LiveVue Slot Non-ASCII Character Tests" do
    test "renders non-ASCII characters in slots correctly", %{page: page} do
      Page.goto!(page, "/slot-test")
      sync_lv(page)

      # Test 1: Polish characters
      polish_slot = slot(page, "Polish")
      Expect.to_contain_text!(polish_slot, "Zażółć gęślą jaźń")

      # Test 2: Japanese characters
      japanese_slot = slot(page, "Japanese")
      Expect.to_contain_text!(japanese_slot, "こんにちは世界")

      # Test 3: Emoji
      emoji_slot = slot(page, "Emoji")
      Expect.to_contain_text!(emoji_slot, "Hello 🌍 World 🎉 Party 🚀")

      # Test 4: Mixed scripts (Russian, Chinese, Arabic)
      mixed_slot = slot(page, "Mixed")
      Expect.to_contain_text!(mixed_slot, "Привет мир!")
      Expect.to_contain_text!(mixed_slot, "你好世界!")
      Expect.to_contain_text!(mixed_slot, "مرحبا بالعالم")

      # Test 5: Special Latin characters
      special_slot = slot(page, "Special")
      Expect.to_contain_text!(special_slot, "Ñoño café résumé naïve")
    end
  end
end

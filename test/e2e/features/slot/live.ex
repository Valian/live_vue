defmodule LiveVue.E2E.SlotTestLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Non-ASCII Slot Test</h1>

      <LiveVue.vue id="slot-polish" v-component="slot_test" label="Test 1: Polish">
        Zażółć gęślą jaźń
      </LiveVue.vue>

      <LiveVue.vue id="slot-japanese" v-component="slot_test" label="Test 2: Japanese">
        こんにちは世界
      </LiveVue.vue>

      <LiveVue.vue id="slot-emoji" v-component="slot_test" label="Test 3: Emoji">
        Hello 🌍 World 🎉 Party 🚀
      </LiveVue.vue>

      <LiveVue.vue id="slot-mixed" v-component="slot_test" label="Test 4: Mixed">
        Привет мир! 你好世界! مرحبا بالعالم
      </LiveVue.vue>

      <LiveVue.vue id="slot-special" v-component="slot_test" label="Test 5: Special chars">
        Ñoño café résumé naïve
      </LiveVue.vue>
    </div>
    """
  end
end

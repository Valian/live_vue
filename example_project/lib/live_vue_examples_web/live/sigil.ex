defmodule LiveVueExamplesWeb.LiveSigil do
  use LiveVueExamplesWeb, :live_view

  def render(assigns) do
    ~V"""
    <script setup lang="ts">
    import {ref} from "vue"
    const props = defineProps<{count: number}>()
    const diff = ref<number>(1)
    </script>

    <template>
      <h1 class="text-3xl font-semibold text-center mb-4">Sigil example</h1>
      Current count
      <div class="text-2xl text-bold">{{ props.count }}</div>
      <label class="block mt-8">Diff: </label>
      <input v-model="diff" class="mt-4" type="range" min="1" max="10">

      <button
        phx-click="inc"
        :phx-value-diff="diff"
        class="mt-4 bg-black text-white rounded p-2 block">
        Increase counter {{ diff }}
      </button>
    </template>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("inc", %{"diff" => diff}, socket) do
    {:noreply, update(socket, :count, &(&1 + String.to_integer(diff)))}
  end
end

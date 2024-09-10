<script setup lang="ts">
import ShowState from "./ShowState.vue";
const props = defineProps<{ title: string, tags: string[]}>()
</script>

<template>
  <ShowState :server-state="props" :client-state="{}">
    <div class="max-w-sm rounded overflow-hidden shadow-lg bg-white">
      <img class="w-full" src="../img/card-top.jpeg" alt="Sunset in the mountains">
      <div class="px-6 py-4">
        <div class="font-bold text-xl mb-2"></div>
        <slot></slot>
      </div>
      <div class="px-6 pt-4 pb-2">
        <div class="text-sm text-center text-gray-500 mb-2">There are {{ props.tags.length }} tag</div>
        <span v-for="tag in props.tags" class="inline-block bg-gray-200 rounded-full px-3 py-1 text-sm font-semibold text-gray-700 mr-2 mb-2">{{ tag }}</span>
        <button class="inline-block bg-blue-200 rounded-full px-3 py-1 text-sm font-semibold text-gray-700 mr-2 mb-2" phx-click="add-tag">Add more</button>
        <div class="text-center text-sm text-gray-700 mt-4">
          <slot name="footer"></slot>
        </div>
      </div>
    </div>
  </ShowState>
</template>
<script setup lang="ts">
import { ref } from 'vue'

const props = defineProps<{ count: number }>()
const diff = ref<number>(1)
</script>

<template>
  Current count
  <div class="text-2xl text-bold" data-pw-counter>
    {{ props.count }}
  </div>
  <label class="block mt-8">Diff: </label>
  <input v-model.number="diff" class="mt-4" type="range" min="1" max="10">

  <button class="mt-4 bg-black text-white rounded p-2 block" @click="$live.pushEvent('increment', { value: diff })">
    Increase counter by {{ diff }}
  </button>
</template>

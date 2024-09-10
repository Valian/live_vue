<script setup lang="ts">
  import {ref} from "vue"
  const props = defineProps<{count: number}>()
  const emit = defineEmits<{inc: [{value: number}]}>()
  const diff = ref<string>("1")
</script>

<template>
  Current count
  <div class="text-2xl text-bold">{{ props.count }}</div>
  <label class="block mt-8">Diff: </label>
  <input v-model="diff" class="mt-4" type="range" min="1" max="10">

  <button 
    @click="emit('inc', {value: parseInt(diff)})"
    class="mt-4 bg-black text-white rounded p-2 block">
    Increase counter by {{ diff }}
  </button> 
</template>
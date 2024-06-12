<script setup lang="ts">
import { reactive } from 'vue';
import ShowState from "./ShowState.vue";

const props = defineProps<{
  data: Record<string, any>
}>()
const value = reactive<{name: string, surname: string}>({name: "", surname: ""})
const emits = defineEmits<{
  save: [value: {name: string, surname: string}]
}>()
</script>

<template>
  <ShowState :server-state="props" :client-state="{value}">
    <form class="flex flex-col gap-4">
      <input v-model="value.name" class="rounded" placeholder="name">
      <input v-model="value.surname" class="rounded" placeholder="surname">
      <button
        type="button" 
        @click="emits('save', value)" 
        class="mt-4 bg-black text-white rounded p-2 block"
      >
        Save
      </button>

    </form>
  </ShowState>
</template>
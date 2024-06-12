<script setup lang="ts">
import {ref} from "vue"
import ShowState from "./ShowState.vue";
const props = defineProps<{count: number}>()
const emit = defineEmits<{inc: [{value: number}]}>()
const diff = ref<string>("1")
</script>

<template>
  <ShowState :server-state="props" :client-state="{diff}">
    Current count

    <Transition mode="out-in">
      <div :key="props.count" class="text-3xl text-bold">
        {{ props.count }}
      </div>
    </Transition>

    <label class="block mt-8">Diff: </label>
    <input v-model="diff" class="mt-4 w-full" type="range" min="1" max="10">

    <button 
      @click="emit('inc', {value: parseInt(diff)})"
      class="mt-4 bg-black text-white rounded p-2 block">
      Increase counter by {{ parseInt(diff) * 2 }}
    </button> 
  </ShowState>
</template>















<style scoped>

.v-enter-active,
.v-leave-active {
  position: relative;
  transition: all 0.1s ease;
}

.v-enter-from {
  transform: translateY(-50%);
}

.v-leave-to {
  transform: translateY(50%);
}

.v-enter-from,
.v-leave-to {
  opacity: 0;
}

</style>
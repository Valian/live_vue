<script setup lang="ts">
const props = defineProps<{ count: number; label: string }>()
</script>

<template>
  <div data-pw-count>{{ props.count }}</div>
  <div data-pw-label>{{ props.label }}</div>
  <button @click="$live.pushEvent('update', {})">Update</button>
</template>

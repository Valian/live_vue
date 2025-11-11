<script setup lang="ts">
const props = defineProps<{
  data: any
}>()
</script>

<template>
  <div>
    <h2>Props Display Component</h2>
    <pre data-testid="props-json">{{ JSON.stringify(props.data, null, 2) }}</pre>
  </div>
</template>

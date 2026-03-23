<script setup lang="ts">
defineProps<{ label: string; layoutCount: number }>()
</script>

<template>
  <div data-pw-sidebar-content>{{ label }} (layout: {{ layoutCount }})</div>
</template>

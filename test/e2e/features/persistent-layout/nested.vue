<script setup lang="ts">
defineProps<{ message: string }>()
</script>

<template>
  <p data-pw-nested>{{ message }}</p>
</template>

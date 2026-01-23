<script setup lang="ts">
defineProps<{ message: string }>()
</script>

<template>
  <div data-pw-dead-view>
    <p>Vue component in dead view:</p>
    <p data-pw-vue-message>{{ message }}</p>
  </div>
</template>

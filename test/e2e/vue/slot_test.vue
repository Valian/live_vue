<script setup lang="ts">
defineProps<{ label?: string }>()
</script>

<template>
  <div class="slot-test">
    <span v-if="label" data-pw-label>{{ label }}</span>
    <div data-pw-slot>
      <slot />
    </div>
  </div>
</template>

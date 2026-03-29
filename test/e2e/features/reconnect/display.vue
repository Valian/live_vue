<script setup lang="ts">
const props = defineProps<{ count: number; label: string; items: any[] }>()
</script>

<template>
  <div data-pw-count>{{ props.count }}</div>
  <div data-pw-label>{{ props.label }}</div>
  <div data-pw-items>
    <span v-for="item in props.items" :key="item.__dom_id" :data-pw-item="item.id">{{ item.name }}</span>
  </div>
  <div data-pw-item-count>{{ props.items?.length ?? 0 }}</div>
  <button @click="$live.pushEvent('update', {})">Update</button>
</template>

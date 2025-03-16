<template>
  <div class="test-component">
    <h2>{{ title }}</h2>
    <div class="content">
      <slot></slot>
    </div>
    <div class="actions">
      <button @click="emitEvent" class="btn">{{ buttonText }}</button>
    </div>
  </div>
</template>

<script setup>
import { defineProps, defineEmits } from 'vue';

const props = defineProps({
  title: {
    type: String,
    default: 'Test Component'
  },
  buttonText: {
    type: String,
    default: 'Click Me'
  }
});

const emit = defineEmits(['test-event']);

const emitEvent = () => {
  emit('test-event', { message: 'Test event triggered' });
};
</script>

<style scoped>
.test-component {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 16px;
  margin: 16px 0;
  background-color: #f9f9f9;
}

.content {
  margin: 16px 0;
}

.btn {
  background-color: #3b82f6;
  color: white;
  padding: 8px 16px;
  border-radius: 4px;
  border: none;
  cursor: pointer;
}

.btn:hover {
  background-color: #2563eb;
}
</style> 
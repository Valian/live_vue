<script setup lang="ts">
import { computed } from 'vue';

interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  class?: string;
}

const props = withDefaults(defineProps<ButtonProps>(), {
  variant: 'primary',
  size: 'md',
  disabled: false,
  class: ''
});

const variantClasses = computed(() => {
  switch (props.variant) {
    case 'primary':
      return 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500';
    case 'secondary':
      return 'bg-gray-500 text-white hover:bg-gray-600 focus:ring-gray-400';
    case 'outline':
      return 'bg-transparent border border-blue-600 text-blue-600 hover:bg-blue-50 focus:ring-blue-500';
    case 'ghost':
      return 'bg-transparent text-blue-600 hover:bg-blue-50 focus:ring-blue-500';
    default:
      return 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500';
  }
});

const sizeClasses = computed(() => {
  switch (props.size) {
    case 'sm':
      return 'px-2 py-1 text-sm';
    case 'md':
      return 'px-4 py-2 text-base';
    case 'lg':
      return 'px-6 py-3 text-lg';
    default:
      return 'px-4 py-2 text-base';
  }
});

const buttonClasses = computed(() => {
  return [
    'inline-flex items-center justify-center rounded-md font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors',
    variantClasses.value,
    sizeClasses.value,
    props.disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer',
    props.class
  ].filter(Boolean).join(' ');
});
</script>

<template>
  <button
    :class="buttonClasses"
    :disabled="disabled"
  >
    <slot></slot>
  </button>
</template> 
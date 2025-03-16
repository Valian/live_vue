<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import {
  Dialog,
  DialogPanel,
  DialogTitle,
  DialogDescription,
  DialogOverlay,
  DialogClose
} from '@reka-ui/dialog';

interface ModalProps {
  title: string;
  open?: boolean;
  maxWidth?: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | 'full';
  closeOnEsc?: boolean;
  closeOnOutsideClick?: boolean;
}

const props = withDefaults(defineProps<ModalProps>(), {
  open: false,
  maxWidth: 'md',
  closeOnEsc: true,
  closeOnOutsideClick: true
});

const emit = defineEmits<{
  (e: 'close'): void;
}>();

// For controlled mode
const isOpen = ref(props.open);

// Watch for changes to the open prop
watch(() => props.open, (newValue) => {
  isOpen.value = newValue;
});

// Update parent when modal is closed internally
const handleClose = () => {
  isOpen.value = false;
  emit('close');
};

// Max width classes
const maxWidthClasses = computed(() => {
  switch (props.maxWidth) {
    case 'sm':
      return 'max-w-sm';
    case 'md':
      return 'max-w-md';
    case 'lg':
      return 'max-w-lg';
    case 'xl':
      return 'max-w-xl';
    case '2xl':
      return 'max-w-2xl';
    case 'full':
      return 'max-w-full';
    default:
      return 'max-w-md';
  }
});
</script>

<template>
  <Dialog 
    :open="isOpen" 
    @close="handleClose"
    :closeOnEsc="closeOnEsc"
    :closeOnOutsideClick="closeOnOutsideClick"
    class="relative z-50"
  >
    <!-- Backdrop -->
    <div class="fixed inset-0 bg-black/30" aria-hidden="true" />
    
    <!-- Full-screen container to center the panel -->
    <div class="fixed inset-0 flex items-center justify-center p-4">
      <DialogPanel 
        :class="['w-full bg-white rounded-lg shadow-xl transform transition-all', maxWidthClasses]"
      >
        <!-- Header -->
        <div class="px-6 py-4 border-b border-gray-100 flex justify-between items-center">
          <DialogTitle class="text-lg font-medium text-gray-900">
            {{ title }}
          </DialogTitle>
          <DialogClose 
            class="text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 rounded-full p-1"
          >
            <span class="sr-only">Close</span>
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </DialogClose>
        </div>
        
        <!-- Content -->
        <div class="px-6 py-4">
          <slot></slot>
        </div>
        
        <!-- Footer slot if provided -->
        <div v-if="$slots.footer" class="px-6 py-4 border-t border-gray-100 flex justify-end space-x-3">
          <slot name="footer"></slot>
        </div>
        
        <!-- Default footer if no slot provided -->
        <div v-else-if="$slots.default" class="px-6 py-4 border-t border-gray-100 flex justify-end space-x-3">
          <DialogClose 
            class="px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200"
          >
            Cancel
          </DialogClose>
          <button 
            class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
          >
            Confirm
          </button>
        </div>
      </DialogPanel>
    </div>
  </Dialog>
</template> 
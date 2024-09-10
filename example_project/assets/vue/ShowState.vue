<script setup lang="ts">
  const props = defineProps<{
    serverState: Record<string, any>,
    clientState: Record<string, any>
  }>()
</script>

<template>
  <div class="grid grid-cols-2 gap-2 min-h-80 grid-rows-2">
    <div class="row-span-2 flex items-center justify-center bg-gray-200 p-4 rounded-lg">
      <div class="text-black">
        <slot />
      </div>
    </div>
    <div class="p-2 rounded-lg bg-orange-200 text-black">
      <p class="text-center font-semibold">
        Server side state
      </p>
      <pre class="overflow-y-auto max-h-60">{{ props.serverState }}</pre>
    </div>
    <div class="p-2 rounded-lg bg-green-200 text-black">
      <p class="text-center font-semibold">
        Client side state
      </p>
      <pre class="overflow-y-auto max-h-60">{{ props.clientState }}</pre>
    </div>
  </div>
</template>


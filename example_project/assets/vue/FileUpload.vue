<script setup lang="ts">
import { computed } from "vue"
import { useLiveUpload, UploadConfig } from "live_vue"
import { UploadEntry } from "../../../priv/static/types"

// Props from LiveView - simplified typing
const props = defineProps<{
  upload: UploadConfig
  uploadedFiles: { name: string; size: number; type: string }[]
}>()

// Use the upload composable
const { entries, showFilePicker, addFiles, submit, cancel, clear, progress } = useLiveUpload(() => props.upload, {
  changeEvent: "validate",
  submitEvent: "save",
})

// Handle drag and drop
const handleDrop = (event: DragEvent) => {
  event.preventDefault()
  if (event.dataTransfer?.files) {
    const files = Array.from(event.dataTransfer.files)
    addFiles(files)
  }
}

const handleDragOver = (event: DragEvent) => {
  event.preventDefault()
}

// Format file size helper
const formatFileSize = (bytes: number): string => {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`
  if (bytes < 1024 * 1024 * 1024) return `${Math.round(bytes / (1024 * 1024))} MB`
  return `${Math.round(bytes / (1024 * 1024 * 1024))} GB`
}

// Error message helper
const getErrorMessage = (error: string): string => {
  switch (error) {
    case "too_large":
      return "File is too large"
    case "too_many_files":
      return "Too many files"
    case "not_accepted":
      return "File type not accepted"
    default:
      return "Invalid file"
  }
}

// Computed values to avoid template access issues
const hasEntries = computed(() => entries.value && entries.value.length > 0)
const hasProgress = computed(() => progress.value > 0)
const entriesCount = computed(() => (entries.value ? entries.value.length : 0))
const progressValue = computed(() => progress.value)
</script>

<template>
  <div class="max-w-2xl mx-auto p-6">
    <div class="space-y-6">
      <!-- Upload Area -->
      <div class="space-y-2">
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300"> Upload Files (Vue Component) </label>

        <div
          class="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 dark:border-gray-600 border-dashed rounded-md hover:border-indigo-400 dark:hover:border-indigo-500 transition-colors"
          :phx-drop-target="upload.ref"
          @drop="handleDrop"
          @dragover="handleDragOver"
        >
          <div class="space-y-4 text-center">
            <div class="flex flex-col items-center space-y-2">
              <button
                @click="showFilePicker"
                class="relative cursor-pointer bg-indigo-600 dark:bg-indigo-500 text-white rounded-lg font-medium hover:bg-indigo-700 dark:hover:bg-indigo-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 px-6 py-3 shadow-sm transition-colors"
              >
                Choose Files
              </button>
              <p class="text-sm text-gray-600 dark:text-gray-400">or drag and drop files here</p>
            </div>

            <p class="text-xs text-gray-500 dark:text-gray-400">
              {{ upload.accept || "Any file type" }} • Max {{ upload.max_entries }} files
            </p>
          </div>
        </div>
      </div>

      <!-- Progress Bar -->
      <div v-if="hasEntries && hasProgress" class="space-y-2">
        <div class="flex justify-between text-sm">
          <span class="text-gray-700 dark:text-gray-300">Overall Progress</span>
          <span class="text-gray-500 dark:text-gray-400">{{ progressValue }}%</span>
        </div>
        <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
          <div
            class="bg-indigo-600 dark:bg-indigo-500 h-2 rounded-full transition-all duration-300"
            :style="{ width: `${progressValue}%` }"
          ></div>
        </div>
      </div>

      <!-- File List -->
      <div v-if="hasEntries" class="space-y-4">
        <div class="flex justify-between items-center">
          <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100">Selected Files ({{ entriesCount }})</h3>
          <div class="space-x-2">
            <button
              v-if="!upload.auto_upload"
              @click="submit"
              class="px-4 py-2 bg-green-600 dark:bg-green-500 text-white rounded-md hover:bg-green-700 dark:hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-green-500 text-sm"
            >
              Upload All
            </button>
            <button
              @click="cancel()"
              class="px-4 py-2 bg-red-600 dark:bg-red-500 text-white rounded-md hover:bg-red-700 dark:hover:bg-red-600 focus:outline-none focus:ring-2 focus:ring-red-500 text-sm"
            >
              Cancel All
            </button>
            <button
              @click="clear"
              class="px-4 py-2 bg-gray-600 dark:bg-gray-500 text-white rounded-md hover:bg-gray-700 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-gray-500 text-sm"
            >
              Clear
            </button>
          </div>
        </div>

        <div class="space-y-3">
          <div
            v-for="entry in entries as unknown as UploadEntry[]"
            :key="entry.ref"
            class="flex items-center justify-between p-4 border border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800"
          >
            <div class="flex items-center space-x-3">
              <div class="flex-shrink-0">
                <div
                  v-if="entry.client_type && entry.client_type.startsWith('image/')"
                  class="h-12 w-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center"
                >
                  <svg
                    class="h-6 w-6 text-blue-600 dark:text-blue-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                    />
                  </svg>
                </div>
                <div v-else class="h-12 w-12 bg-gray-100 dark:bg-gray-700 rounded-lg flex items-center justify-center">
                  <svg
                    class="h-6 w-6 text-gray-400 dark:text-gray-500"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                    />
                  </svg>
                </div>
              </div>

              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">
                  {{ entry.client_name }}
                </p>
                <p class="text-sm text-gray-500 dark:text-gray-400">
                  {{ formatFileSize(entry.client_size) }} • {{ entry.client_type }}
                </p>

                <!-- Progress for individual entry -->
                <div v-if="entry.progress > 0 && entry.progress < 100" class="mt-2">
                  <div class="flex justify-between text-xs">
                    <span class="text-gray-500 dark:text-gray-400">Uploading...</span>
                    <span class="text-gray-500 dark:text-gray-400">{{ entry.progress }}%</span>
                  </div>
                  <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1 mt-1">
                    <div
                      class="bg-indigo-600 dark:bg-indigo-500 h-1 rounded-full transition-all duration-300"
                      :style="{ width: `${entry.progress}%` }"
                    ></div>
                  </div>
                </div>

                <!-- Status indicators -->
                <div class="flex items-center space-x-2 mt-1">
                  <span
                    v-if="entry.done"
                    class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200"
                  >
                    ✓ Complete
                  </span>
                  <span
                    v-else-if="!entry.valid"
                    class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-200"
                  >
                    ✗ Invalid
                  </span>
                  <span
                    v-else-if="entry.progress > 0"
                    class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200"
                  >
                    ↻ Uploading
                  </span>
                  <span
                    v-else
                    class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-200"
                  >
                    Ready
                  </span>
                </div>
              </div>
            </div>

            <div class="flex items-center space-x-2">
              <button
                @click="cancel(entry.ref)"
                class="text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-300 p-1"
                title="Cancel upload"
              >
                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Uploaded Files -->
      <div v-if="props.uploadedFiles.length > 0" class="space-y-4">
        <div class="flex justify-between items-center">
          <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100">
            Uploaded Files ({{ props.uploadedFiles.length }})
          </h3>
        </div>

        <div class="space-y-3">
          <div
            v-for="file in props.uploadedFiles"
            :key="file.name"
            class="flex items-center justify-between p-4 border border-green-200 dark:border-green-700 rounded-lg bg-green-50 dark:bg-green-900/20"
          >
            <div class="flex items-center space-x-3">
              <div class="flex-shrink-0">
                <div
                  v-if="file.type && file.type.startsWith('image/')"
                  class="h-12 w-12 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center"
                >
                  <svg
                    class="h-6 w-6 text-green-600 dark:text-green-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                    />
                  </svg>
                </div>
                <div
                  v-else
                  class="h-12 w-12 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center"
                >
                  <svg
                    class="h-6 w-6 text-green-600 dark:text-green-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                    />
                  </svg>
                </div>
              </div>

              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium text-gray-900 dark:text-gray-100 truncate">
                  {{ file.name }}
                </p>
                <p class="text-sm text-gray-500 dark:text-gray-400">
                  {{ formatFileSize(file.size) }} • {{ file.type }}
                </p>
                <div class="flex items-center space-x-2 mt-1">
                  <span
                    class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200"
                  >
                    ✓ Uploaded Successfully
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Upload Errors -->
      <div v-if="upload.errors && upload.errors.length > 0" class="space-y-2">
        <h4 class="text-sm font-medium text-red-800 dark:text-red-200">Upload Errors:</h4>
        <div
          v-for="{ ref, error } in upload.errors"
          :key="ref"
          class="text-sm text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 p-3 rounded-md"
        >
          {{ getErrorMessage(error) }}
        </div>
      </div>

      <!-- Debug Info (can be removed in production) -->
      <p class="cursor-pointer text-sm text-gray-500 dark:text-gray-400 mt-8">Debug Info</p>
      <pre class="mt-2 text-xs bg-gray-100 dark:bg-gray-800 p-4 rounded overflow-auto">{{
        JSON.stringify({ upload }, null, 2)
      }}</pre>

      <pre class="mt-2 text-xs bg-gray-100 dark:bg-gray-800 p-4 rounded overflow-auto">{{
        JSON.stringify({ uploadedFiles: props.uploadedFiles }, null, 2)
      }}</pre>
    </div>
  </div>
</template>

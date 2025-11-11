<script setup lang="ts">
import type { UploadConfig, UploadEntry } from 'live_vue'
import { useLiveUpload } from 'live_vue'
import { computed } from 'vue'

interface Props {
  upload: UploadConfig
  uploadedFiles: { name: string, size: number, type: string }[]
}

const props = defineProps<Props>()

const { entries, showFilePicker, addFiles, submit, cancel } = useLiveUpload(() => props.upload, {
  changeEvent: 'validate',
  submitEvent: 'save',
})

// Computed properties to handle reactive values
const entriesList = computed(() => entries.value || [])
const entriesCount = computed(() => entriesList.value.length)

// Global errors handling
const hasGlobalErrors = computed(() => props.upload.errors && props.upload.errors.length > 0)
const globalErrorEntries = computed(() => props.upload.errors)

function getEntryName(ref: string) {
  const entry = entriesList.value.find((e: UploadEntry) => e.ref === ref)
  return entry ? entry.client_name : `Entry ${ref}`
}

// Handle drag and drop
function handleDrop(event: DragEvent) {
  event.preventDefault()
  if (event.dataTransfer?.files) {
    const files = Array.from(event.dataTransfer.files)
    addFiles(files)
  }
}

function handleDragOver(event: DragEvent) {
  event.preventDefault()
}
</script>

<template>
  <div class="upload-container">
    <div id="upload-info" class="info-section">
      <div id="max-entries" class="info-item">
        Max entries: {{ upload.max_entries }}
      </div>
      <div id="auto-upload" class="info-item">
        Auto upload: {{ upload.auto_upload }}
      </div>
      <div id="selected-count" class="info-item">
        Selected files: {{ entriesCount }}
      </div>
    </div>

    <div class="upload-controls">
      <button id="select-files-btn" class="btn btn-primary" @click="showFilePicker">
        Select Files
      </button>

      <button v-if="!upload.auto_upload && entriesCount > 0" id="upload-btn" class="btn btn-success" @click="submit">
        Upload Files
      </button>

      <button v-if="entriesCount > 0" id="cancel-all-btn" class="btn btn-danger" @click="cancel()">
        Cancel All
      </button>
    </div>

    <!-- Drag and Drop Zone -->
    <div id="drop-zone" class="drop-zone" :phx-drop-target="upload.ref" @drop="handleDrop" @dragover="handleDragOver">
      <p>Drag and drop files here</p>
    </div>

    <div id="file-list" class="file-list">
      <div v-for="entry in entriesList" :key="entry.ref" :data-entry-ref="entry.ref" class="file-entry">
        <div class="file-info">
          <span class="file-name">{{ entry.client_name }}</span>
          <span class="file-size">{{ entry.client_size }} bytes</span>
          <span class="file-progress">{{ entry.progress || 0 }}%</span>
          <span class="file-done" :class="{ 'status-done': entry.done, 'status-pending': !entry.done }">
            {{ entry.done ? "done" : "pending" }}
          </span>
        </div>

        <!-- Error display for each entry -->
        <div v-if="entry.errors && entry.errors.length > 0" class="entry-errors">
          <div v-for="error in entry.errors" :key="error" class="error-message">
            {{ error }}
          </div>
        </div>

        <button class="cancel-entry-btn btn btn-sm" @click="cancel(entry.ref)">
          ×
        </button>
      </div>
    </div>

    <div id="uploaded-files" class="uploaded-files">
      <h3 v-if="uploadedFiles.length > 0">
        Uploaded Files
      </h3>
      <div v-for="file in uploadedFiles" :key="file.name" class="uploaded-file">
        <span class="uploaded-name">{{ file.name }}</span>
        <span class="uploaded-size">{{ file.size }} bytes</span>
      </div>
    </div>

    <!-- Global upload errors -->
    <div v-if="hasGlobalErrors" id="global-errors" class="global-errors">
      <h4>Upload Errors:</h4>
      <div v-for="error in globalErrorEntries" :key="error.ref" class="global-error">
        <strong>{{ getEntryName(error.ref) }}:</strong>
        <div class="error-message">
          {{ error.error }}
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.upload-container {
  max-width: 600px;
  margin: 20px auto;
  padding: 20px;
  font-family: Arial, sans-serif;
}

.info-section {
  background: #f5f5f5;
  padding: 15px;
  border-radius: 8px;
  margin-bottom: 20px;
}

.info-item {
  margin: 5px 0;
  font-weight: 500;
}

.upload-controls {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}

.btn {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
  transition: background-color 0.2s;
}

.btn-primary {
  background-color: #007bff;
  color: white;
}

.btn-primary:hover {
  background-color: #0056b3;
}

.btn-success {
  background-color: #28a745;
  color: white;
}

.btn-success:hover {
  background-color: #1e7e34;
}

.btn-danger {
  background-color: #dc3545;
  color: white;
}

.btn-danger:hover {
  background-color: #c82333;
}

.btn-sm {
  padding: 4px 8px;
  font-size: 12px;
  background-color: #6c757d;
  color: white;
}

.btn-sm:hover {
  background-color: #545b62;
}

.file-list {
  margin-bottom: 20px;
}

.file-entry {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  margin-bottom: 10px;
  background: white;
}

.file-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.file-name {
  font-weight: 600;
  color: #333;
}

.file-size,
.file-progress {
  font-size: 12px;
  color: #666;
}

.status-done {
  color: #28a745;
  font-weight: 500;
}

.status-pending {
  color: #ffc107;
  font-weight: 500;
}

.entry-errors {
  margin-top: 8px;
  padding: 8px;
  background-color: #f8d7da;
  border: 1px solid #f5c6cb;
  border-radius: 4px;
}

.error-message {
  color: #721c24;
  font-size: 12px;
  margin: 2px 0;
}

.cancel-entry-btn {
  margin-left: 10px;
  align-self: flex-start;
}

.uploaded-files {
  margin-top: 20px;
}

.uploaded-files h3 {
  margin-bottom: 10px;
  color: #28a745;
}

.uploaded-file {
  display: flex;
  justify-content: space-between;
  padding: 8px 12px;
  background: #d4edda;
  border: 1px solid #c3e6cb;
  border-radius: 4px;
  margin-bottom: 5px;
}

.uploaded-name {
  font-weight: 500;
}

.uploaded-size {
  color: #666;
  font-size: 12px;
}

.global-errors {
  margin-top: 20px;
  padding: 15px;
  background-color: #f8d7da;
  border: 1px solid #f5c6cb;
  border-radius: 6px;
}

.global-errors h4 {
  margin: 0 0 10px 0;
  color: #721c24;
}

.global-error {
  margin-bottom: 8px;
}

.global-error strong {
  color: #721c24;
}

.drop-zone {
  border: 2px dashed #ccc;
  border-radius: 8px;
  padding: 20px;
  text-align: center;
  margin: 20px 0;
  background-color: #f9f9f9;
  transition: border-color 0.2s, background-color 0.2s;
}

.drop-zone:hover {
  border-color: #007bff;
  background-color: #f0f8ff;
}

.drop-zone p {
  margin: 0;
  color: #666;
  font-size: 14px;
}
</style>

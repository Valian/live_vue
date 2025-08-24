<script setup lang="ts">
import { useEventReply } from "live_vue"

const props = defineProps<{
  counter: number
}>()

// Different event reply composables for testing
const incrementReply = useEventReply<{counter: number, timestamp: string}>("increment")
const userReply = useEventReply<{id: number, name: string, email: string}>("get-user")
const errorReply = useEventReply("error-event")
const slowReply = useEventReply<{message: string, completed_at: string}>("slow-event")
const pingReply = useEventReply<{response: string, timestamp: string}>("ping")
const dataTypeReply = useEventReply("get-data-type")
const validateReply = useEventReply<{valid: boolean, error?: string, message?: string}>("validate-input")

// Test increment functionality
const handleIncrement = async (by: number) => {
  try {
    const result = await incrementReply.execute({ by })
    console.log("Increment result:", result)
  } catch (error) {
    console.error("Increment error:", error)
  }
}

// Test user data fetching
const fetchUser = async (id: number) => {
  try {
    const result = await userReply.execute({ id })
    console.log("User data:", result)
  } catch (error) {
    console.error("User fetch error:", error)
  }
}

// Test error handling
const triggerError = async () => {
  try {
    const result = await errorReply.execute()
    console.log("Error result:", result)
  } catch (error) {
    console.error("Expected error:", error)
  }
}

// Test slow event with cancellation
const startSlowEvent = async (delay: number) => {
  try {
    const result = await slowReply.execute({ delay })
    console.log("Slow event result:", result)
  } catch (error) {
    console.error("Slow event error:", error)
  }
}

const cancelSlowEvent = () => {
  slowReply.cancel()
}

// Test ping without parameters
const ping = async () => {
  try {
    const result = await pingReply.execute()
    console.log("Ping result:", result)
  } catch (error) {
    console.error("Ping error:", error)
  }
}

// Test different data types
const testDataType = async (type: string) => {
  try {
    const result = await dataTypeReply.execute({ type })
    console.log(`Data type ${type} result:`, result)
  } catch (error) {
    console.error(`Data type ${type} error:`, error)
  }
}

// Test input validation
const validateShortInput = async () => {
  try {
    const result = await validateReply.execute({ input: "Hi" })
    console.log("Validation result:", result)
  } catch (error) {
    console.error("Validation error:", error)
  }
}

const validateValidInput = async () => {
  try {
    const result = await validateReply.execute({ input: "Valid Input" })
    console.log("Validation result:", result)
  } catch (error) {
    console.error("Validation error:", error)
  }
}

const validateLongInput = async () => {
  try {
    const result = await validateReply.execute({ input: "This is a very long input that exceeds the maximum allowed length" })
    console.log("Validation result:", result)
  } catch (error) {
    console.error("Validation error:", error)
  }
}
</script>

<template>
  <div class="event-reply-test" data-pw-event-reply-test>
    <h2>useEventReply Tests</h2>

    <!-- Server State Display -->
    <div class="server-state" data-pw-server-state>
      <p data-pw-server-counter>Server Counter: {{ counter }}</p>
    </div>

    <!-- Basic Increment Test -->
    <div class="section">
      <h3>Increment Test</h3>
      <div class="controls">
        <button @click="handleIncrement(1)" data-pw-increment-1>+1</button>
        <button @click="handleIncrement(5)" data-pw-increment-5>+5</button>
      </div>
      <div class="state">
        <div data-pw-increment-loading>Loading: {{ incrementReply.isLoading.value }}</div>
        <div data-pw-increment-data>Data: {{ JSON.stringify(incrementReply.data.value) }}</div>
      </div>
    </div>

    <!-- User Data Test -->
    <div class="section">
      <h3>User Data Test</h3>
      <div class="controls">
        <button @click="fetchUser(1)" data-pw-fetch-user-1>Fetch User 1</button>
        <button @click="fetchUser(2)" data-pw-fetch-user-2>Fetch User 2</button>
        <button @click="fetchUser(999)" data-pw-fetch-user-999>Fetch User 999</button>
      </div>
      <div class="state">
        <div data-pw-user-loading>Loading: {{ userReply.isLoading.value }}</div>
        <div data-pw-user-data>Data: {{ JSON.stringify(userReply.data.value) }}</div>
      </div>
    </div>

    <!-- Error Handling Test -->
    <div class="section">
      <h3>Server Error Response Test</h3>
      <div class="controls">
        <button @click="triggerError" data-pw-trigger-error>Trigger Server Error Response</button>
      </div>
      <div class="state">
        <div data-pw-error-loading>Loading: {{ errorReply.isLoading.value }}</div>
        <div data-pw-error-data>Data: {{ JSON.stringify(errorReply.data.value) }}</div>
      </div>
    </div>

    <!-- Cancellation Test -->
    <div class="section">
      <h3>Cancellation Test</h3>
      <div class="controls">
        <button @click="startSlowEvent(2000)" data-pw-start-slow>Start Slow (2s)</button>
        <button @click="cancelSlowEvent" data-pw-cancel-slow>Cancel</button>
      </div>
      <div class="state">
        <div data-pw-slow-loading>Loading: {{ slowReply.isLoading.value }}</div>
        <div data-pw-slow-data>Data: {{ JSON.stringify(slowReply.data.value) }}</div>
      </div>
    </div>

    <!-- No Parameters Test -->
    <div class="section">
      <h3>No Parameters Test</h3>
      <div class="controls">
        <button @click="ping" data-pw-ping>Ping</button>
      </div>
      <div class="state">
        <div data-pw-ping-loading>Loading: {{ pingReply.isLoading.value }}</div>
        <div data-pw-ping-data>Data: {{ JSON.stringify(pingReply.data.value) }}</div>
      </div>
    </div>

    <!-- Data Types Test -->
    <div class="section">
      <h3>Data Types Test</h3>
      <div class="controls">
        <button @click="testDataType('string')" data-pw-test-string>String</button>
        <button @click="testDataType('number')" data-pw-test-number>Number</button>
        <button @click="testDataType('boolean')" data-pw-test-boolean>Boolean</button>
        <button @click="testDataType('array')" data-pw-test-array>Array</button>
        <button @click="testDataType('object')" data-pw-test-object>Object</button>
        <button @click="testDataType('null')" data-pw-test-null>Null</button>
      </div>
      <div class="state">
        <div data-pw-datatype-loading>Loading: {{ dataTypeReply.isLoading.value }}</div>
        <div data-pw-datatype-data>Data: {{ JSON.stringify(dataTypeReply.data.value) }}</div>
      </div>
    </div>

    <!-- Input Validation Test -->
    <div class="section">
      <h3>Input Validation Test</h3>
      <div class="controls">
        <button @click="validateShortInput" data-pw-validate-short>Short Input</button>
        <button @click="validateValidInput" data-pw-validate-valid>Valid Input</button>
        <button @click="validateLongInput" data-pw-validate-long>Long Input</button>
      </div>
      <div class="state">
        <div data-pw-validate-loading>Loading: {{ validateReply.isLoading.value }}</div>
        <div data-pw-validate-data>Data: {{ JSON.stringify(validateReply.data.value) }}</div>
      </div>
    </div>

    <!-- Concurrent Execution Test -->
    <div class="section">
      <h3>Concurrent Execution Test</h3>
      <div class="controls">
        <button @click="startSlowEvent(1000)" data-pw-concurrent-first>Start First</button>
        <button @click="startSlowEvent(500)" data-pw-concurrent-second>Try Second (Should Fail)</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.event-reply-test {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.section {
  border: 1px solid #ddd;
  margin: 20px 0;
  padding: 15px;
  border-radius: 8px;
}

.section h3 {
  margin-top: 0;
  color: #333;
}

.controls {
  display: flex;
  gap: 10px;
  margin: 10px 0;
  flex-wrap: wrap;
}

.controls button {
  padding: 8px 12px;
  border: none;
  border-radius: 4px;
  background: #007bff;
  color: white;
  cursor: pointer;
  font-size: 14px;
}

.controls button:hover {
  background: #0056b3;
}

.state {
  background: #f8f9fa;
  padding: 10px;
  border-radius: 4px;
  margin-top: 10px;
  font-family: monospace;
  font-size: 12px;
}

.state div {
  margin: 5px 0;
  word-wrap: break-word;
}

.server-state {
  background: #e9ecef;
  padding: 10px;
  border-radius: 4px;
  margin-bottom: 20px;
}
</style>
<script setup lang="ts">
import { useEventReply } from 'live_vue'

const props = defineProps<{
  counter: number
}>()

// Different event reply composables for testing
const incrementReply = useEventReply<{ counter: number, timestamp: string }>('increment')
const userReply = useEventReply<{ id: number, name: string, email: string }>('get-user')
const errorReply = useEventReply('error-event')
const slowReply = useEventReply<{ message: string, completed_at: string }>('slow-event')
const pingReply = useEventReply<{ response: string, timestamp: string }>('ping')
const dataTypeReply = useEventReply('get-data-type')
const validateReply = useEventReply<{ valid: boolean, error?: string, message?: string }>('validate-input')

// Test increment functionality
async function handleIncrement(by: number) {
  try {
    const result = await incrementReply.execute({ by })
    console.log('Increment result:', result)
  }
  catch (error) {
    console.error('Increment error:', error)
  }
}

// Test user data fetching
async function fetchUser(id: number) {
  try {
    const result = await userReply.execute({ id })
    console.log('User data:', result)
  }
  catch (error) {
    console.error('User fetch error:', error)
  }
}

// Test error handling
async function triggerError() {
  try {
    const result = await errorReply.execute()
    console.log('Error result:', result)
  }
  catch (error) {
    console.error('Expected error:', error)
  }
}

// Test slow event with cancellation
async function startSlowEvent(delay: number) {
  try {
    const result = await slowReply.execute({ delay })
    console.log('Slow event result:', result)
  }
  catch (error) {
    console.error('Slow event error:', error)
  }
}

function cancelSlowEvent() {
  slowReply.cancel()
}

// Test ping without parameters
async function ping() {
  try {
    const result = await pingReply.execute()
    console.log('Ping result:', result)
  }
  catch (error) {
    console.error('Ping error:', error)
  }
}

// Test different data types
async function testDataType(type: string) {
  try {
    const result = await dataTypeReply.execute({ type })
    console.log(`Data type ${type} result:`, result)
  }
  catch (error) {
    console.error(`Data type ${type} error:`, error)
  }
}

// Test input validation
async function validateShortInput() {
  try {
    const result = await validateReply.execute({ input: 'Hi' })
    console.log('Validation result:', result)
  }
  catch (error) {
    console.error('Validation error:', error)
  }
}

async function validateValidInput() {
  try {
    const result = await validateReply.execute({ input: 'Valid Input' })
    console.log('Validation result:', result)
  }
  catch (error) {
    console.error('Validation error:', error)
  }
}

async function validateLongInput() {
  try {
    const result = await validateReply.execute({ input: 'This is a very long input that exceeds the maximum allowed length' })
    console.log('Validation result:', result)
  }
  catch (error) {
    console.error('Validation error:', error)
  }
}
</script>

<template>
  <div class="event-reply-test" data-pw-event-reply-test>
    <h2>useEventReply Tests</h2>

    <!-- Server State Display -->
    <div class="server-state" data-pw-server-state>
      <p data-pw-server-counter>
        Server Counter: {{ counter }}
      </p>
    </div>

    <!-- Basic Increment Test -->
    <div class="section">
      <h3>Increment Test</h3>
      <div class="controls">
        <button data-pw-increment-1 @click="handleIncrement(1)">
          +1
        </button>
        <button data-pw-increment-5 @click="handleIncrement(5)">
          +5
        </button>
      </div>
      <div class="state">
        <div data-pw-increment-loading>
          Loading: {{ incrementReply.isLoading.value }}
        </div>
        <div data-pw-increment-data>
          Data: {{ JSON.stringify(incrementReply.data.value) }}
        </div>
      </div>
    </div>

    <!-- User Data Test -->
    <div class="section">
      <h3>User Data Test</h3>
      <div class="controls">
        <button data-pw-fetch-user-1 @click="fetchUser(1)">
          Fetch User 1
        </button>
        <button data-pw-fetch-user-2 @click="fetchUser(2)">
          Fetch User 2
        </button>
        <button data-pw-fetch-user-999 @click="fetchUser(999)">
          Fetch User 999
        </button>
      </div>
      <div class="state">
        <div data-pw-user-loading>
          Loading: {{ userReply.isLoading.value }}
        </div>
        <div data-pw-user-data>
          Data: {{ JSON.stringify(userReply.data.value) }}
        </div>
      </div>
    </div>

    <!-- Error Handling Test -->
    <div class="section">
      <h3>Server Error Response Test</h3>
      <div class="controls">
        <button data-pw-trigger-error @click="triggerError">
          Trigger Server Error Response
        </button>
      </div>
      <div class="state">
        <div data-pw-error-loading>
          Loading: {{ errorReply.isLoading.value }}
        </div>
        <div data-pw-error-data>
          Data: {{ JSON.stringify(errorReply.data.value) }}
        </div>
      </div>
    </div>

    <!-- Cancellation Test -->
    <div class="section">
      <h3>Cancellation Test</h3>
      <div class="controls">
        <button data-pw-start-slow @click="startSlowEvent(2000)">
          Start Slow (2s)
        </button>
        <button data-pw-cancel-slow @click="cancelSlowEvent">
          Cancel
        </button>
      </div>
      <div class="state">
        <div data-pw-slow-loading>
          Loading: {{ slowReply.isLoading.value }}
        </div>
        <div data-pw-slow-data>
          Data: {{ JSON.stringify(slowReply.data.value) }}
        </div>
      </div>
    </div>

    <!-- No Parameters Test -->
    <div class="section">
      <h3>No Parameters Test</h3>
      <div class="controls">
        <button data-pw-ping @click="ping">
          Ping
        </button>
      </div>
      <div class="state">
        <div data-pw-ping-loading>
          Loading: {{ pingReply.isLoading.value }}
        </div>
        <div data-pw-ping-data>
          Data: {{ JSON.stringify(pingReply.data.value) }}
        </div>
      </div>
    </div>

    <!-- Data Types Test -->
    <div class="section">
      <h3>Data Types Test</h3>
      <div class="controls">
        <button data-pw-test-string @click="testDataType('string')">
          String
        </button>
        <button data-pw-test-number @click="testDataType('number')">
          Number
        </button>
        <button data-pw-test-boolean @click="testDataType('boolean')">
          Boolean
        </button>
        <button data-pw-test-array @click="testDataType('array')">
          Array
        </button>
        <button data-pw-test-object @click="testDataType('object')">
          Object
        </button>
        <button data-pw-test-null @click="testDataType('null')">
          Null
        </button>
      </div>
      <div class="state">
        <div data-pw-datatype-loading>
          Loading: {{ dataTypeReply.isLoading.value }}
        </div>
        <div data-pw-datatype-data>
          Data: {{ JSON.stringify(dataTypeReply.data.value) }}
        </div>
      </div>
    </div>

    <!-- Input Validation Test -->
    <div class="section">
      <h3>Input Validation Test</h3>
      <div class="controls">
        <button data-pw-validate-short @click="validateShortInput">
          Short Input
        </button>
        <button data-pw-validate-valid @click="validateValidInput">
          Valid Input
        </button>
        <button data-pw-validate-long @click="validateLongInput">
          Long Input
        </button>
      </div>
      <div class="state">
        <div data-pw-validate-loading>
          Loading: {{ validateReply.isLoading.value }}
        </div>
        <div data-pw-validate-data>
          Data: {{ JSON.stringify(validateReply.data.value) }}
        </div>
      </div>
    </div>

    <!-- Concurrent Execution Test -->
    <div class="section">
      <h3>Concurrent Execution Test</h3>
      <div class="controls">
        <button data-pw-concurrent-first @click="startSlowEvent(1000)">
          Start First
        </button>
        <button data-pw-concurrent-second @click="startSlowEvent(500)">
          Try Second (Should Fail)
        </button>
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

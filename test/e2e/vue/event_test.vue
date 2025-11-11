<script setup lang="ts">
import { useLiveEvent, useLiveVue } from 'live_vue'
import { ref } from 'vue'

interface Props {
  message: string
  event_count: number
}

interface NotificationEvent {
  message: string
  timestamp: number
}

interface CustomEvent {
  data: string
  count: number
}

const props = defineProps<Props>()
const live = useLiveVue()

const messageInput = ref('')
const customDataInput = ref('')
const notificationEvents = ref<NotificationEvent[]>([])
const customEvents = ref<CustomEvent[]>([])

// Listen for notification events from the server
useLiveEvent<NotificationEvent>('notification', (data) => {
  notificationEvents.value.push(data)
})

// Listen for custom events from the server
useLiveEvent<CustomEvent>('custom_event', (data) => {
  customEvents.value.push(data)
})

function sendNotification() {
  if (messageInput.value.trim()) {
    live.pushEvent('send_notification', { message: messageInput.value })
    messageInput.value = ''
  }
}

function sendCustomEvent() {
  if (customDataInput.value.trim()) {
    live.pushEvent('send_custom_event', { data: customDataInput.value })
    customDataInput.value = ''
  }
}
</script>

<template>
  <div>
    <h1>Event Test</h1>

    <div>
      <label for="message-input">Message:</label>
      <input id="message-input" v-model="messageInput" type="text">
      <button id="send-notification-btn" @click="sendNotification">
        Send Notification
      </button>
    </div>

    <div>
      <label for="custom-data-input">Custom Data:</label>
      <input id="custom-data-input" v-model="customDataInput" type="text">
      <button id="send-custom-btn" @click="sendCustomEvent">
        Send Custom Event
      </button>
    </div>

    <div id="received-events">
      <h3>Received Events:</h3>
      <div id="notification-events">
        <strong>Notifications:</strong>
        <ul>
          <li v-for="(event, index) in notificationEvents" :key="index" class="notification-event">
            {{ event.message }} ({{ event.timestamp }})
          </li>
        </ul>
      </div>
      <div id="custom-events">
        <strong>Custom Events:</strong>
        <ul>
          <li v-for="(event, index) in customEvents" :key="index" class="custom-event">
            {{ event.data }} (count: {{ event.count }})
          </li>
        </ul>
      </div>
    </div>

    <div id="event-counters">
      <div id="notification-count">
        Notification Count: {{ notificationEvents.length }}
      </div>
      <div id="custom-count">
        Custom Event Count: {{ customEvents.length }}
      </div>
    </div>
  </div>
</template>

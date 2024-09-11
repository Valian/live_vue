<template>
    <v-row class="fill-height">
        <v-col>
            <v-sheet height="600">
                <v-calendar ref="calendar" v-model="today" :events="events" color="primary" type="month"></v-calendar>
            </v-sheet>
        </v-col>
    </v-row>
</template>

<script setup>
import { onMounted, ref } from "vue"
import { useDate } from "vuetify"

const calendar = ref()

const today = ref([new Date()])
const events = ref([])
const colors = ["blue", "indigo", "deep-purple", "cyan", "green", "orange", "grey darken-1"]
const names = ["Meeting", "Holiday", "PTO", "Travel", "Event", "Birthday", "Conference", "Party"]

onMounted(() => {
    const adapter = useDate()
    fetchEvents({
        start: adapter.startOfDay(adapter.startOfMonth(new Date())),
        end: adapter.endOfDay(adapter.endOfMonth(new Date())),
    })
})
function fetchEvents({ start, end }) {
    const _events = []
    const min = start
    const max = end
    const days = (max.getTime() - min.getTime()) / 86400000
    const eventCount = rnd(days, days + 20)
    for (let i = 0; i < eventCount; i++) {
        const allDay = rnd(0, 3) === 0
        const firstTimestamp = rnd(min.getTime(), max.getTime())
        const first = new Date(firstTimestamp - (firstTimestamp % 900000))
        const secondTimestamp = rnd(2, allDay ? 288 : 8) * 900000
        const second = new Date(first.getTime() + secondTimestamp)
        _events.push({
            title: names[rnd(0, names.length - 1)],
            start: first,
            end: second,
            color: colors[rnd(0, colors.length - 1)],
            allDay: !allDay,
        })
    }
    events.value = _events
}
function rnd(a, b) {
    return Math.floor((b - a + 1) * Math.random()) + a
}
</script>

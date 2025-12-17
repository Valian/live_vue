import { test, expect } from '@playwright/test'
import { syncLV } from '../../utils.js'

test.describe('useLiveEvent', () => {
  test('should receive notification events from server', async ({ page }) => {
    await page.goto('/events')
    await syncLV(page)

    // Verify initial state
    await expect(page.locator('#notification-count')).toContainText('Notification Count: 0')
    await expect(page.locator('#custom-count')).toContainText('Custom Event Count: 0')

    // Send a notification event
    await page.fill('#message-input', 'Hello from test!')
    await page.click('#send-notification-btn')
    await syncLV(page)

    // Verify notification event was received
    await expect(page.locator('#notification-count')).toContainText('Notification Count: 1')
    await expect(page.locator('.notification-event')).toContainText('Hello from test!')
    
    // Verify the message appears in both LiveView state and Vue component
    await expect(page.locator('#message-display')).toContainText('Message: Hello from test!')
    await expect(page.locator('#event-count')).toContainText('Event Count: 1')

    // Send another notification
    await page.fill('#message-input', 'Second message')
    await page.click('#send-notification-btn')
    await syncLV(page)

    // Verify both notifications are received
    await expect(page.locator('#notification-count')).toContainText('Notification Count: 2')
    await expect(page.locator('.notification-event')).toHaveCount(2)
    await expect(page.locator('.notification-event').nth(1)).toContainText('Second message')
  })

  test('should receive custom events from server', async ({ page }) => {
    await page.goto('/events')
    await syncLV(page)

    // Send a custom event
    await page.fill('#custom-data-input', 'Custom data payload')
    await page.click('#send-custom-btn')
    await syncLV(page)

    // Verify custom event was received
    await expect(page.locator('#custom-count')).toContainText('Custom Event Count: 1')
    await expect(page.locator('.custom-event')).toContainText('Custom data payload (count: 1)')
    await expect(page.locator('#event-count')).toContainText('Event Count: 1')

    // Send another custom event
    await page.fill('#custom-data-input', 'Another payload')
    await page.click('#send-custom-btn')
    await syncLV(page)

    // Verify both custom events are received
    await expect(page.locator('#custom-count')).toContainText('Custom Event Count: 2')
    await expect(page.locator('.custom-event')).toHaveCount(2)
    await expect(page.locator('.custom-event').nth(1)).toContainText('Another payload (count: 2)')
  })

  test('should handle mixed notification and custom events', async ({ page }) => {
    await page.goto('/events')
    await syncLV(page)

    // Send notification
    await page.fill('#message-input', 'Mixed test notification')
    await page.click('#send-notification-btn')
    await syncLV(page)

    // Send custom event
    await page.fill('#custom-data-input', 'Mixed test custom')
    await page.click('#send-custom-btn')
    await syncLV(page)

    // Send another notification
    await page.fill('#message-input', 'Second notification')
    await page.click('#send-notification-btn')
    await syncLV(page)

    // Verify all events are received correctly
    await expect(page.locator('#notification-count')).toContainText('Notification Count: 2')
    await expect(page.locator('#custom-count')).toContainText('Custom Event Count: 1')
    await expect(page.locator('#event-count')).toContainText('Event Count: 3')

    // Verify event contents
    await expect(page.locator('.notification-event').nth(0)).toContainText('Mixed test notification')
    await expect(page.locator('.custom-event').nth(0)).toContainText('Mixed test custom (count: 2)')
    await expect(page.locator('.notification-event').nth(1)).toContainText('Second notification')
  })

  test('should handle rapid sequential events', async ({ page }) => {
    await page.goto('/events')
    await syncLV(page)

    // Send multiple events rapidly
    for (let i = 1; i <= 5; i++) {
      await page.fill('#message-input', `Rapid message ${i}`)
      await page.click('#send-notification-btn')
    }
    
    await syncLV(page)

    // Verify all events are received
    await expect(page.locator('#notification-count')).toContainText('Notification Count: 5')
    await expect(page.locator('.notification-event')).toHaveCount(5)
    await expect(page.locator('#event-count')).toContainText('Event Count: 5')

    // Verify first and last messages
    await expect(page.locator('.notification-event').nth(0)).toContainText('Rapid message 1')
    await expect(page.locator('.notification-event').nth(4)).toContainText('Rapid message 5')
  })
})
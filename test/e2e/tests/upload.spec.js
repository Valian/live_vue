import { test, expect } from "@playwright/test"
import { syncLV } from "../utils.js"
import { readFileSync } from "fs"
import { join } from "path"

test.describe("useLiveUpload", () => {
  // Helper function to create test files
  const createTestFile = (name, content = "test content") => {
    return new File([content], name, { type: "text/plain" })
  }

  test("should handle manual upload (auto_upload: false)", async ({ page }) => {
    await page.goto("/upload/manual")
    await syncLV(page)

    // Verify initial state
    await expect(page.locator("#upload-mode")).toContainText("manual")
    await expect(page.locator("#auto-upload")).toContainText("false")
    await expect(page.locator("#selected-count")).toContainText("0")
    await expect(page.locator("#uploaded-count")).toContainText("0")

    // Upload button should not be visible initially
    await expect(page.locator("#upload-btn")).not.toBeVisible()

    // Create a test file and simulate file selection
    const testContent = "This is test file content for manual upload"
    await page.setInputFiles('input[type="file"]', {
      name: "test-manual.txt",
      mimeType: "text/plain",
      buffer: Buffer.from(testContent),
    })

    await syncLV(page)

    // Verify file is selected but not uploaded yet
    await expect(page.locator("#selected-count")).toContainText("1")
    await expect(page.locator("#uploaded-count")).toContainText("0")

    // Upload button should now be visible
    await expect(page.locator("#upload-btn")).toBeVisible()

    // Verify file appears in file list
    await expect(page.locator(".file-entry")).toHaveCount(1)
    await expect(page.locator(".file-name")).toContainText("test-manual.txt")
    await expect(page.locator(".file-done")).toContainText("pending")

    // Click upload button to manually trigger upload
    await page.click("#upload-btn")
    await syncLV(page)

    // Wait for upload to complete and verify
    await expect(page.locator("#uploaded-count")).toContainText("1")
    await expect(page.locator(".uploaded-file")).toHaveCount(1)
    await expect(page.locator(".uploaded-name")).toContainText("test-manual.txt")
  })

  test("should handle automatic upload (auto_upload: true)", async ({ page }) => {
    await page.goto("/upload/auto")
    await syncLV(page)

    // Verify initial state
    await expect(page.locator("#upload-mode")).toContainText("auto")
    await expect(page.locator("#auto-upload")).toContainText("true")
    await expect(page.locator("#selected-count")).toContainText("0")
    await expect(page.locator("#uploaded-count")).toContainText("0")

    // Upload button should not be visible for auto upload
    await expect(page.locator("#upload-btn")).not.toBeVisible()

    // Create a test file and simulate file selection
    const testContent = "This is test file content for auto upload"
    await page.setInputFiles('input[type="file"]', {
      name: "test-auto.txt",
      mimeType: "text/plain",
      buffer: Buffer.from(testContent),
    })

    await syncLV(page)

    // For auto upload, file should be uploaded automatically
    // Wait a bit longer for the auto upload to process
    await page.waitForTimeout(2000)
    await syncLV(page)

    // Verify file was selected and processed
    await expect(page.locator("#selected-count")).toContainText("1")
    await expect(page.locator(".file-entry")).toHaveCount(1)

    // Check if the file was processed (either uploaded or marked as done)
    const fileStatus = await page.locator(".file-done").textContent()
    const uploadedCount = await page.locator("#uploaded-count").textContent()

    // For auto upload, the file should either be uploaded or marked as done
    expect(fileStatus?.includes("done") || uploadedCount?.includes("1")).toBeTruthy()
  })

  test("should handle multiple file selection and upload", async ({ page }) => {
    await page.goto("/upload/manual")
    await syncLV(page)

    // Select multiple files
    await page.setInputFiles('input[type="file"]', [
      {
        name: "file1.txt",
        mimeType: "text/plain",
        buffer: Buffer.from("Content of file 1"),
      },
      {
        name: "file2.txt",
        mimeType: "text/plain",
        buffer: Buffer.from("Content of file 2"),
      },
    ])

    await syncLV(page)

    // Verify multiple files are selected
    await expect(page.locator("#selected-count")).toContainText("2")
    await expect(page.locator(".file-entry")).toHaveCount(2)

    // Upload all files
    await page.click("#upload-btn")
    await syncLV(page)

    // Verify all files were uploaded
    await expect(page.locator("#uploaded-count")).toContainText("2")
    await expect(page.locator(".uploaded-file")).toHaveCount(2)
  })

  test("should handle file cancellation", async ({ page }) => {
    await page.goto("/upload/manual")
    await syncLV(page)

    // Select a file
    await page.setInputFiles('input[type="file"]', {
      name: "cancel-test.txt",
      mimeType: "text/plain",
      buffer: Buffer.from("This file will be cancelled"),
    })

    await syncLV(page)

    // Verify file is selected
    await expect(page.locator("#selected-count")).toContainText("1")
    await expect(page.locator(".file-entry")).toHaveCount(1)

    // Cancel the file
    await page.click("#cancel-all-btn")
    await syncLV(page)

    // Verify file was cancelled
    await expect(page.locator("#selected-count")).toContainText("0")
    await expect(page.locator(".file-entry")).toHaveCount(0)
    await expect(page.locator("#uploaded-count")).toContainText("0")
  })

  test("should respect max_entries limit", async ({ page }) => {
    await page.goto("/upload/manual")
    await syncLV(page)

    // Verify max entries is displayed
    await expect(page.locator("#max-entries")).toContainText("3")

    // Select exactly max_entries files (3)
    await page.setInputFiles('input[type="file"]', [
      { name: "file1.txt", mimeType: "text/plain", buffer: Buffer.from("1") },
      { name: "file2.txt", mimeType: "text/plain", buffer: Buffer.from("2") },
      { name: "file3.txt", mimeType: "text/plain", buffer: Buffer.from("3") },
    ])

    await syncLV(page)

    // Should accept exactly max_entries (3 files)
    await expect(page.locator("#selected-count")).toContainText("3")
    await expect(page.locator(".file-entry")).toHaveCount(3)
  })

  test("should handle file size errors", async ({ page }) => {
    await page.goto("/upload/manual")
    await syncLV(page)

    // Try to upload a file larger than max_file_size (1MB)
    const largeContent = "x".repeat(2000000) // 2MB file
    await page.setInputFiles('input[type="file"]', {
      name: "large-file.txt",
      mimeType: "text/plain",
      buffer: Buffer.from(largeContent),
    })

    await syncLV(page)

    // File should be selected but may have errors
    await expect(page.locator("#selected-count")).toContainText("1")
    await expect(page.locator(".file-entry")).toHaveCount(1)

    // Check if error handling is working (specific error messages may vary)
    // The file might be rejected or show error state
    const hasErrors = await page
      .locator("#global-errors")
      .isVisible()
      .catch(() => false)
    const hasEntryErrors = await page
      .locator(".entry-errors")
      .isVisible()
      .catch(() => false)

    // At least one error display should be present for oversized files
    expect(hasErrors || hasEntryErrors).toBeTruthy()
  })

  test("should handle unsupported file type errors", async ({ page }) => {
    await page.goto("/upload/manual")
    await syncLV(page)

    // Try to upload a file type not in accept list (.exe not in .txt .pdf .jpg .png)
    await page.setInputFiles('input[type="file"]', {
      name: "program.exe",
      mimeType: "application/octet-stream",
      buffer: Buffer.from("fake exe content"),
    })

    await syncLV(page)

    // File should be selected but may have errors
    await expect(page.locator("#selected-count")).toContainText("1")

    // Check if error handling is working for unsupported file types
    const hasErrors = await page
      .locator("#global-errors")
      .isVisible()
      .catch(() => false)
    const hasEntryErrors = await page
      .locator(".entry-errors")
      .isVisible()
      .catch(() => false)

    // At least one error display should be present for unsupported file types
    expect(hasErrors || hasEntryErrors).toBeTruthy()
  })

  test("should handle too many files error", async ({ page }) => {
    await page.goto("/upload/manual")
    await syncLV(page)

    // Try to select more files than max_entries allows (4 files when max is 3)
    await page.setInputFiles('input[type="file"]', [
      { name: "file1.txt", mimeType: "text/plain", buffer: Buffer.from("1") },
      { name: "file2.txt", mimeType: "text/plain", buffer: Buffer.from("2") },
      { name: "file3.txt", mimeType: "text/plain", buffer: Buffer.from("3") },
      { name: "file4.txt", mimeType: "text/plain", buffer: Buffer.from("4") },
    ])

    await syncLV(page)

    // Either only 3 files are accepted, or there's an error about too many files
    const selectedCount = await page.locator("#selected-count").textContent()
    expect(await page.locator(".file-entry").count()).toEqual(4)

    // Should either limit to max_entries or show error
    // If more than 3 files are shown, there should be an error
    const hasErrors = await page
      .locator("#global-errors")
      .isVisible()
      .catch(() => false)
    expect(hasErrors).toBeTruthy()
  })
})

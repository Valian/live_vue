defmodule LiveVue.E2E.UploadTest do
  use LiveVue.E2E.Case, async: true

  # `isVisible().catch(() => false)`
  defp visible?(locator) do
    case Locator.is_visible(locator) do
      {:ok, visible} -> visible
      {:error, _} -> false
    end
  end

  describe "useLiveUpload" do
    test "should handle manual upload (auto_upload: false)", %{page: page} do
      Page.goto!(page, "/upload/manual")
      sync_lv(page)

      # Verify initial state
      Expect.to_contain_text!(Page.locator(page, "#upload-mode"), "manual")
      Expect.to_contain_text!(Page.locator(page, "#auto-upload"), "false")
      Expect.to_contain_text!(Page.locator(page, "#selected-count"), "0")
      Expect.to_contain_text!(Page.locator(page, "#uploaded-count"), "0")

      # Upload button should not be visible initially
      page |> Page.locator("#upload-btn") |> Expect.not_() |> Expect.to_be_visible!()

      # Create a test file and simulate file selection
      test_content = "This is test file content for manual upload"

      Page.set_input_files!(page, ~s(input[type="file"]), %{
        name: "test-manual.txt",
        mimeType: "text/plain",
        buffer: test_content
      })

      sync_lv(page)

      # Verify file is selected but not uploaded yet
      Expect.to_contain_text!(Page.locator(page, "#selected-count"), "1")
      Expect.to_contain_text!(Page.locator(page, "#uploaded-count"), "0")

      # Upload button should now be visible
      Expect.to_be_visible!(Page.locator(page, "#upload-btn"))

      # Verify file appears in file list
      Expect.to_have_count!(Page.locator(page, ".file-entry"), 1)
      Expect.to_contain_text!(Page.locator(page, ".file-name"), "test-manual.txt")
      Expect.to_contain_text!(Page.locator(page, ".file-done"), "pending")

      # Click upload button to manually trigger upload
      Page.click!(page, "#upload-btn")
      sync_lv(page)

      # Wait for upload to complete and verify
      Expect.to_contain_text!(Page.locator(page, "#uploaded-count"), "1")
      Expect.to_have_count!(Page.locator(page, ".uploaded-file"), 1)
      Expect.to_contain_text!(Page.locator(page, ".uploaded-name"), "test-manual.txt")
    end

    test "should handle automatic upload (auto_upload: true)", %{page: page} do
      Page.goto!(page, "/upload/auto")
      sync_lv(page)

      # Verify initial state
      Expect.to_contain_text!(Page.locator(page, "#upload-mode"), "auto")
      Expect.to_contain_text!(Page.locator(page, "#auto-upload"), "true")
      Expect.to_contain_text!(Page.locator(page, "#selected-count"), "0")
      Expect.to_contain_text!(Page.locator(page, "#uploaded-count"), "0")

      # Upload button should not be visible for auto upload
      page |> Page.locator("#upload-btn") |> Expect.not_() |> Expect.to_be_visible!()

      # Create a test file and simulate file selection
      test_content = "This is test file content for auto upload"

      Page.set_input_files!(page, ~s(input[type="file"]), %{
        name: "test-auto.txt",
        mimeType: "text/plain",
        buffer: test_content
      })

      sync_lv(page)

      # For auto upload, file should be uploaded automatically
      # Wait a bit longer for the auto upload to process
      Page.wait_for_timeout!(page, 2000)
      sync_lv(page)

      # Verify file was selected and processed
      Expect.to_contain_text!(Page.locator(page, "#selected-count"), "1")
      Expect.to_have_count!(Page.locator(page, ".file-entry"), 1)

      # Check if the file was processed (either uploaded or marked as done)
      file_status = Locator.text_content!(Page.locator(page, ".file-done"))
      uploaded_count = Locator.text_content!(Page.locator(page, "#uploaded-count"))

      # For auto upload, the file should either be uploaded or marked as done
      assert (is_binary(file_status) and file_status =~ "done") or
               (is_binary(uploaded_count) and uploaded_count =~ "1")
    end

    test "should handle multiple file selection and upload", %{page: page} do
      Page.goto!(page, "/upload/manual")
      sync_lv(page)

      # Select multiple files
      Page.set_input_files!(page, ~s(input[type="file"]), [
        %{name: "file1.txt", mimeType: "text/plain", buffer: "Content of file 1"},
        %{name: "file2.txt", mimeType: "text/plain", buffer: "Content of file 2"}
      ])

      sync_lv(page)

      # Verify multiple files are selected
      Expect.to_contain_text!(Page.locator(page, "#selected-count"), "2")
      Expect.to_have_count!(Page.locator(page, ".file-entry"), 2)

      # Upload all files
      Page.click!(page, "#upload-btn")
      sync_lv(page)

      # Verify all files were uploaded
      Expect.to_contain_text!(Page.locator(page, "#uploaded-count"), "2")
      Expect.to_have_count!(Page.locator(page, ".uploaded-file"), 2)
    end

    test "should handle file cancellation", %{page: page} do
      Page.goto!(page, "/upload/manual")
      sync_lv(page)

      # Select a file
      Page.set_input_files!(page, ~s(input[type="file"]), %{
        name: "cancel-test.txt",
        mimeType: "text/plain",
        buffer: "This file will be cancelled"
      })

      sync_lv(page)

      # Verify file is selected
      Expect.to_contain_text!(Page.locator(page, "#selected-count"), "1")
      Expect.to_have_count!(Page.locator(page, ".file-entry"), 1)

      # Cancel the file
      Page.click!(page, "#cancel-all-btn")
      sync_lv(page)

      # Verify file was cancelled
      Expect.to_contain_text!(Page.locator(page, "#selected-count"), "0")
      Expect.to_have_count!(Page.locator(page, ".file-entry"), 0)
      Expect.to_contain_text!(Page.locator(page, "#uploaded-count"), "0")
    end

    test "should respect max_entries limit", %{page: page} do
      Page.goto!(page, "/upload/manual")
      sync_lv(page)

      # Verify max entries is displayed
      Expect.to_contain_text!(Page.locator(page, "#max-entries"), "3")

      # Select exactly max_entries files (3)
      Page.set_input_files!(page, ~s(input[type="file"]), [
        %{name: "file1.txt", mimeType: "text/plain", buffer: "1"},
        %{name: "file2.txt", mimeType: "text/plain", buffer: "2"},
        %{name: "file3.txt", mimeType: "text/plain", buffer: "3"}
      ])

      sync_lv(page)

      # Should accept exactly max_entries (3 files)
      Expect.to_contain_text!(Page.locator(page, "#selected-count"), "3")
      Expect.to_have_count!(Page.locator(page, ".file-entry"), 3)
    end

    test "should handle file size errors", %{page: page} do
      Page.goto!(page, "/upload/manual")
      sync_lv(page)

      # Try to upload a file larger than max_file_size (1MB)
      # 2MB file
      large_content = String.duplicate("x", 2_000_000)

      Page.set_input_files!(page, ~s(input[type="file"]), %{
        name: "large-file.txt",
        mimeType: "text/plain",
        buffer: large_content
      })

      sync_lv(page)

      # File should be selected but may have errors
      Expect.to_contain_text!(Page.locator(page, "#selected-count"), "1")
      Expect.to_have_count!(Page.locator(page, ".file-entry"), 1)

      # Check if error handling is working (specific error messages may vary)
      # The file might be rejected or show error state
      has_errors = visible?(Page.locator(page, "#global-errors"))
      has_entry_errors = visible?(Page.locator(page, ".entry-errors"))

      # At least one error display should be present for oversized files
      assert has_errors or has_entry_errors
    end

    test "should handle unsupported file type errors", %{page: page} do
      Page.goto!(page, "/upload/manual")
      sync_lv(page)

      # Try to upload a file type not in accept list (.exe not in .txt .pdf .jpg .png)
      Page.set_input_files!(page, ~s(input[type="file"]), %{
        name: "program.exe",
        mimeType: "application/octet-stream",
        buffer: "fake exe content"
      })

      sync_lv(page)

      # File should be selected but may have errors
      Expect.to_contain_text!(Page.locator(page, "#selected-count"), "1")

      # Check if error handling is working for unsupported file types
      has_errors = visible?(Page.locator(page, "#global-errors"))
      has_entry_errors = visible?(Page.locator(page, ".entry-errors"))

      # At least one error display should be present for unsupported file types
      assert has_errors or has_entry_errors
    end

    test "should handle too many files error", %{page: page} do
      Page.goto!(page, "/upload/manual")
      sync_lv(page)

      # Try to select more files than max_entries allows (4 files when max is 3)
      Page.set_input_files!(page, ~s(input[type="file"]), [
        %{name: "file1.txt", mimeType: "text/plain", buffer: "1"},
        %{name: "file2.txt", mimeType: "text/plain", buffer: "2"},
        %{name: "file3.txt", mimeType: "text/plain", buffer: "3"},
        %{name: "file4.txt", mimeType: "text/plain", buffer: "4"}
      ])

      sync_lv(page)

      # Either only 3 files are accepted, or there's an error about too many files
      _selected_count = Locator.text_content!(Page.locator(page, "#selected-count"))
      assert Locator.count!(Page.locator(page, ".file-entry")) == 4

      # Should either limit to max_entries or show error
      # If more than 3 files are shown, there should be an error
      has_errors = visible?(Page.locator(page, "#global-errors"))
      assert has_errors
    end

    test "should handle drag and drop file upload", %{page: page} do
      Page.goto!(page, "/upload/manual")
      sync_lv(page)

      # Verify initial state
      Expect.to_contain_text!(Page.locator(page, "#selected-count"), "0")

      # Create a DataTransfer object with files for drag and drop simulation
      test_content = "This is test file content for drag and drop"

      # Simulate drag and drop by dispatching a drop event with files
      Page.evaluate!(
        page,
        """
        async content => {
          const dropArea = document.querySelector("#drop-zone")
          if (!dropArea) throw new Error("Drop area not found")

          // Create a File object
          const file = new File([content], "drag-drop-test.txt", { type: "text/plain" })

          // Create DataTransfer object and add the file
          const dataTransfer = new DataTransfer()
          dataTransfer.items.add(file)

          // Create and dispatch drop event
          const dropEvent = new DragEvent("drop", {
            bubbles: true,
            cancelable: true,
            dataTransfer: dataTransfer,
          })

          dropArea.dispatchEvent(dropEvent)
        }
        """,
        test_content
      )

      sync_lv(page)

      # Verify file was added via drag and drop
      Expect.to_contain_text!(Page.locator(page, "#selected-count"), "1")
      Expect.to_have_count!(Page.locator(page, ".file-entry"), 1)
      Expect.to_contain_text!(Page.locator(page, ".file-name"), "drag-drop-test.txt")
      Expect.to_contain_text!(Page.locator(page, ".file-done"), "pending")

      # Upload button should now be visible for manual upload
      Expect.to_be_visible!(Page.locator(page, "#upload-btn"))

      # Test that the upload works after drag and drop
      Page.click!(page, "#upload-btn")
      sync_lv(page)

      # Verify upload completed
      Expect.to_contain_text!(Page.locator(page, "#uploaded-count"), "1")
      Expect.to_have_count!(Page.locator(page, ".uploaded-file"), 1)
      Expect.to_contain_text!(Page.locator(page, ".uploaded-name"), "drag-drop-test.txt")
    end

    test "should keep the original upload input usable across a simulated reconnect ref rotation",
         %{page: page} do
      Page.goto!(page, "/upload/manual")
      sync_lv(page)

      original_ref =
        Page.evaluate!(page, """
        () => {
          const input = document.querySelector('input[type="file"]')
          if (!input) throw new Error("Upload input not found")
          window.__originalUploadInput = input
          return input.getAttribute("data-phx-upload-ref")
        }
        """)

      eval_lv(
        page,
        """
        socket
        |> Phoenix.LiveView.disallow_upload(:test_files)
        |> Phoenix.LiveView.allow_upload(:test_files,
          accept: ~w(.txt .pdf .jpg .png),
          max_entries: 3,
          max_file_size: 1_000_000,
          auto_upload: false
        )
        """
      )

      Page.wait_for_function!(
        page,
        """
        previousRef => {
          const input = document.querySelector('input[type="file"]')
          return !!input && input.getAttribute("data-phx-upload-ref") !== previousRef
        }
        """,
        original_ref
      )

      sync_lv(page)

      reconnect_state =
        Page.evaluate!(page, """
        () => {
          const currentInput = document.querySelector('input[type="file"]')
          const originalInput = window.__originalUploadInput

          return {
            originalStillAttached: !!originalInput?.isConnected,
            sameNode: originalInput === currentInput,
            currentRef: currentInput?.getAttribute("data-phx-upload-ref"),
          }
        }
        """)

      assert reconnect_state["originalStillAttached"] == true
      assert reconnect_state["sameNode"] == true
      refute reconnect_state["currentRef"] == original_ref

      test_content = "Upload after reconnect through original input handle"

      Page.evaluate!(
        page,
        """
        content => {
          const input = window.__originalUploadInput
          if (!input) throw new Error("Saved upload input not found")

          const file = new File([content], "reconnect-race.txt", { type: "text/plain" })
          const dataTransfer = new DataTransfer()
          dataTransfer.items.add(file)
          input.files = dataTransfer.files
          input.dispatchEvent(new Event("change", { bubbles: true, cancelable: true }))
        }
        """,
        test_content
      )

      sync_lv(page)

      Expect.to_contain_text!(Page.locator(page, "#selected-count"), "1")
      Expect.to_have_count!(Page.locator(page, ".file-entry"), 1)
      Expect.to_contain_text!(Page.locator(page, ".file-name"), "reconnect-race.txt")

      Page.click!(page, "#upload-btn")
      sync_lv(page)

      Expect.to_contain_text!(Page.locator(page, "#uploaded-count"), "1")
      Expect.to_have_count!(Page.locator(page, ".uploaded-file"), 1)
      Expect.to_contain_text!(Page.locator(page, ".uploaded-name"), "reconnect-race.txt")
    end
  end
end

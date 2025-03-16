defmodule LiveVueUI.ComponentsTest do
  use ExUnit.Case, async: true
  
  import Phoenix.LiveViewTest
  import LiveVueUI.Components
  
  describe "button/1" do
    test "renders button with default attributes" do
      html =
        render_component(&button/1, []) do
          "Click me"
        end
        
      assert html =~ "Click me"
      assert html =~ "v-component=\"LiveVueUIButton\""
      assert html =~ "variant=\"primary\""
      assert html =~ "size=\"md\""
    end
    
    test "renders button with custom attributes" do
      html =
        render_component(&button/1, [
          variant: :secondary,
          size: :lg,
          disabled: true,
          class: "custom-class",
          "phx-click": "clicked"
        ]) do
          "Custom Button"
        end
        
      assert html =~ "Custom Button"
      assert html =~ "variant=\"secondary\""
      assert html =~ "size=\"lg\""
      assert html =~ "disabled=\"true\""
      assert html =~ "class=\"custom-class\""
      assert html =~ "phx-click=\"clicked\""
    end
  end
  
  describe "modal/1" do
    test "renders modal with default attributes" do
      html =
        render_component(&modal/1, [title: "Test Modal"]) do
          "Modal content"
        end
        
      assert html =~ "v-component=\"LiveVueUIModal\""
      assert html =~ "title=\"Test Modal\""
      assert html =~ "Modal content"
    end
    
    test "renders modal with on_close event" do
      html =
        render_component(&modal/1, [
          title: "Test Modal",
          open: true,
          on_close: "modal_closed"
        ]) do
          "Modal content"
        end
        
      assert html =~ "v-component=\"LiveVueUIModal\""
      assert html =~ "title=\"Test Modal\""
      assert html =~ "open=\"true\""
      assert html =~ "v-on:close="
      assert html =~ "push(\"modal_closed\""
    end
  end
end 
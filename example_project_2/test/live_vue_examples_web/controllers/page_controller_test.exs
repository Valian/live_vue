defmodule LiveVueExamplesWeb.PageControllerTest do
  use LiveVueExamplesWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)
    
    # Test main heading
    assert response =~ "Vue inside Phoenix LiveView"
    
    # Test tagline
    assert response =~ "Seamless end-to-end reactivity with the best of both worlds"
    
    # Test CTA buttons
    assert response =~ "Get Started"
    assert response =~ "Try Demo"
    
    # Test feature sections
    assert response =~ "Why LiveVue?"
    assert response =~ "Powerful Features"
    assert response =~ "See It In Action"
    assert response =~ "Get Started in Seconds"
    assert response =~ "Resources & Community"
    
    # Test key features
    assert response =~ "End-To-End Reactivity"
    assert response =~ "One-line Install"
    assert response =~ "Server-Side Rendered"
    assert response =~ "Form Validation"
    assert response =~ "File Uploads"
    
    # Test installation commands
    assert response =~ "mix igniter.install live_vue"
    assert response =~ "mix igniter.new my_app"
    
    # Test links to resources
    assert response =~ "https://hexdocs.pm/live_vue"
    assert response =~ "https://hex.pm/packages/live_vue"
    assert response =~ "https://github.com/Valian/live_vue"
    assert response =~ "https://x.com/jskalc"
    
    # Test code examples
    assert response =~ "defmodule MyAppWeb.CounterLive"
    assert response =~ "handle_event"
    assert response =~ "script setup lang=\"ts\""
    assert response =~ "defineProps"
    
    # Test footer
    assert response =~ "Built with Phoenix + LiveVue"
  end
  
  describe "landing page sections" do
    test "contains hero section with logo", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      assert response =~ "live_vue_logo_rounded.png"
      assert response =~ "LiveVue Logo"
    end
    
    test "contains comparison section", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      assert response =~ "Without LiveVue"
      assert response =~ "With LiveVue"
      assert response =~ "jQuery-style event handlers"
      assert response =~ "Reactive components with Vue.js"
    end
    
    test "contains interactive code examples", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      assert response =~ "LiveView (Server)"
      assert response =~ "Vue Component (Client)"
      assert response =~ "Try Interactive Demo"
    end
    
    test "contains installation instructions", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      assert response =~ "New Project"
      assert response =~ "Existing Project"
      assert response =~ "mix archive.install hex igniter_new"
    end
  end
end

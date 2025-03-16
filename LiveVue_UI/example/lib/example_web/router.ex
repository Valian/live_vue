defmodule LiveVueUIExampleWeb.Router do
  use Phoenix.Router, helpers: false
  import Phoenix.Controller
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LiveVueUIExampleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiveVueUIExampleWeb do
    pipe_through :browser

    live "/", HomeLive, :home
    live "/buttons", ButtonsLive, :buttons
    live "/modals", ModalsLive, :modals
    live "/accordions", AccordionsLive, :accordions
    live "/tabs", TabsLive, :tabs
    live "/dropdowns", DropdownsLive, :dropdowns
    live "/test-component", TestComponentLive, :test_component
  end
end 
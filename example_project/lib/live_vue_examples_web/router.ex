defmodule LiveVueExamplesWeb.Router do
  use LiveVueExamplesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LiveVueExamplesWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiveVueExamplesWeb do
    pipe_through :browser

    live "/", LiveHome
    get "/dead", PageController, :dead
    live "/counter", LiveCounter
    live "/slots", LiveSlots
    live "/form", LiveForm
    live "/sigil", LiveSigil
    live "/prime_vue", LivePrimeVue
    live "/calendar", CalendarLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveVueExamplesWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:live_vue_examples, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LiveVueExamplesWeb.Telemetry
    end
  end
end

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

    live "/dev/vue_demo", VueDemoLive
    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveVueExamplesWeb do
  #   pipe_through :api
  # end
end

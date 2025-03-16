defmodule LiveVueUI do
  @moduledoc """
  LiveVueUI is a comprehensive UI component library built on top of LiveVue.
  
  It provides a set of accessible, customizable UI components that integrate
  Reka UI (a Vue-based UI library) with Phoenix LiveView.
  
  ## Features
  
  * Accessible components based on Reka UI
  * Seamless integration with Phoenix LiveView
  * Tailwind CSS styling
  * Server-Side Rendering (SSR) support
  """
  
  @doc """
  Convenience function that returns a list of components for use in Phoenix LiveView templates.
  
  ## Example
  
      import LiveVueUI
      
      def mount(_params, _session, socket) do
        {:ok, assign(socket, components: LiveVueUI.components())}
      end
  """
  def components do
    [
      # Add components as they are implemented
    ]
  end
  
  @doc """
  Get the path to the LiveVueUI JavaScript assets for Vite configuration.
  """
  def assets_path do
    Path.join(Application.app_dir(:live_vue_ui), "priv/static/live_vue_ui")
  end
end 
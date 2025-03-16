defmodule Mix.Tasks.LiveVueUi.Setup do
  @shortdoc "Sets up LiveVue UI in a Phoenix project"
  @moduledoc """
  Sets up LiveVue UI in a Phoenix project.
  
  This task:
    * Ensures LiveVue is properly set up in the project
    * Installs the necessary npm packages
    * Updates the Vite configuration to include LiveVue UI
    * Configures the Vue app to use LiveVue UI components
  
  ## Examples
  
      $ mix live_vue_ui.setup
  
  """
  
  use Mix.Task
  
  @requirements ["app.config"]
  
  @impl Mix.Task
  def run(_args) do
    if Mix.Project.umbrella?() do
      Mix.raise "mix live_vue_ui.setup can only be run inside an application directory"
    end
    
    # Check if LiveVue is set up
    unless File.exists?("assets/vue") do
      Mix.raise """
      LiveVue is not set up in this project.
      
      Please run `mix live_vue.setup` first to set up LiveVue.
      """
    end
    
    Mix.shell().info([:green, "* Setting up ", :reset, "LiveVue UI"])
    
    # Install npm packages
    install_npm_packages()
    
    # Update Vue app configuration
    update_vue_app()
    
    # Print success message
    Mix.shell().info("""
    
    LiveVue UI has been set up!
    
    You can now use LiveVue UI components in your LiveView templates:
    
        <.button>Click me</.button>
        <.modal title="My Modal" on_close="modal_closed">
          Modal content here
        </.modal>
    
    Don't forget to import the components in your LiveView modules:
    
        import LiveVueUI.Components
    
    """)
  end
  
  defp install_npm_packages do
    Mix.shell().info([:green, "* Installing ", :reset, "npm packages"])
    
    System.cmd("npm", ["install", "--prefix", "assets",
      "@reka-ui/dialog@^0.5.0",
      "@reka-ui/dropdown-menu@^0.5.0",
      "@reka-ui/tabs@^0.5.0",
      "@reka-ui/tooltip@^0.5.0",
      "@reka-ui/popover@^0.5.0",
      "@reka-ui/accordion@^0.5.0",
      "@reka-ui/alert-dialog@^0.5.0"
    ], stderr_to_stdout: true)
  end
  
  defp update_vue_app do
    Mix.shell().info([:green, "* Updating ", :reset, "Vue app"])
    
    # Create the setup file
    create_setup_file()
    
    # Update the main Vue app file to use LiveVue UI
    update_main_vue_file()
  end
  
  defp create_setup_file do
    setup_content = """
    // LiveVue UI setup
    import { setupLiveVueUI } from './live_vue_ui';
    
    export function setupLiveVueUI(app) {
      setupLiveVueUI(app);
    }
    """
    
    File.write!("assets/vue/live_vue_ui.js", setup_content)
  end
  
  defp update_main_vue_file do
    main_vue_file = "assets/vue/index.js"
    
    if File.exists?(main_vue_file) do
      content = File.read!(main_vue_file)
      
      if String.contains?(content, "setupLiveVueUI") do
        Mix.shell().info([:yellow, "* ", :reset, "Vue app already configured for LiveVue UI"])
      else
        # Simple approach - prepend the import statement to the file
        new_content = """
        import { setupLiveVueUI } from './live_vue_ui';
        
        #{content}
        
        // Initialize LiveVue UI
        export function setup(app) {
          setupLiveVueUI(app);
          
          // ... any other existing setup code ...
        }
        """
        
        File.write!(main_vue_file, new_content)
      end
    else
      Mix.shell().error([:red, "* ", :reset, "Could not find #{main_vue_file}"])
      Mix.shell().error([:yellow, "* ", :reset, "Please manually update your Vue app to use LiveVue UI"])
    end
  end
end 
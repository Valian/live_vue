// assets/js/app.js
// This is the main entry point for JavaScript in the example app.
// We'll need to import the Phoenix LiveView JavaScript hooks.

// Import Phoenix dependencies
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

// Import CSS
import "../css/app.css";

// Define hooks
const Hooks = {
  VueHook: {
    mounted() {
      // Get component name and props from data attributes
      const name = this.el.dataset.name;
      const propsStr = this.el.dataset.props || "{}";
      const handlersStr = this.el.dataset.handlers || "{}";
      const slotsStr = this.el.dataset.slots || "{}";
      
      if (!name) {
        console.error("No component name specified for VueHook");
        return;
      }
      
      try {
        // Parse the JSON props, handlers, and slots
        const props = JSON.parse(propsStr);
        const handlers = JSON.parse(handlersStr);
        const slots = JSON.parse(slotsStr);
        
        console.log(`Mounting Vue component: ${name}`, props);
        
        // Render the component based on name
        if (name === "LiveVueUIButton") {
          this.renderButton(props, slots);
        } else {
          console.log(`Unknown component: ${name}`);
          this.el.innerHTML = `<div class="p-4 border border-gray-300 rounded">${name}</div>`;
        }
      } catch (error) {
        console.error(`Error mounting Vue component ${name}:`, error);
      }
    },
    
    renderButton(props, slots) {
      const { variant = "primary", size = "md", disabled = false } = props;
      const slotContent = atob(slots.default || "");
      
      // Generate class names based on variant and size
      const baseClasses = "font-medium rounded focus:outline-none transition-colors";
      
      let variantClasses = '';
      switch (variant) {
        case 'primary':
          variantClasses = "bg-blue-600 hover:bg-blue-700 text-white";
          break;
        case 'secondary':
          variantClasses = "bg-gray-500 hover:bg-gray-600 text-white";
          break;
        case 'outline':
          variantClasses = "bg-transparent border border-blue-600 text-blue-600 hover:bg-blue-50";
          break;
        case 'ghost':
          variantClasses = "bg-transparent text-blue-600 hover:bg-blue-50";
          break;
        default:
          variantClasses = "bg-blue-600 hover:bg-blue-700 text-white";
      }
      
      let sizeClasses = '';
      switch (size) {
        case 'sm':
          sizeClasses = "px-2 py-1 text-sm";
          break;
        case 'md':
          sizeClasses = "px-4 py-2";
          break;
        case 'lg':
          sizeClasses = "px-6 py-3 text-lg";
          break;
        default:
          sizeClasses = "px-4 py-2";
      }
      
      const disabledClasses = disabled ? "opacity-50 cursor-not-allowed" : "cursor-pointer";
      
      const buttonClasses = `${baseClasses} ${variantClasses} ${sizeClasses} ${disabledClasses}`;
      
      // Create the button element with appropriate styling
      this.el.innerHTML = `<button class="${buttonClasses}" ${disabled ? 'disabled' : ''}>${slotContent}</button>`;
      
      // Add event handlers
      if (!disabled) {
        const button = this.el.querySelector('button');
        
        // Find any LiveView event handlers (phx-click, etc)
        Object.entries(props).forEach(([key, value]) => {
          if (key.startsWith('phx-')) {
            console.log(`Adding event handler: ${key} -> ${value}`);
            const eventName = key.replace('phx-', '');
            
            button.addEventListener('click', (e) => {
              e.preventDefault();
              console.log(`Triggering event: ${value}`);
              // Use the correct method to push events to the LiveView
              this.pushEvent(value, {});
            });
          }
        });
      }
    }
  }
};

// LiveView Socket setup with debug logging enabled
const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
  debug: true
});

// Connect if there are any LiveViews on the page
liveSocket.connect();

// Expose liveSocket on window for web console debug logs and latency simulation
window.liveSocket = liveSocket;

// Define app-specific functionality here
document.addEventListener("DOMContentLoaded", () => {
  console.log("LiveVue UI Example loaded");
});

// For hot module replacement in development
if (import.meta.hot) {
  import.meta.hot.accept();
}

export default {}; 
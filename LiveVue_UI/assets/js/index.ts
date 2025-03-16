import type { App } from 'vue';
import Button from '../components/Button.vue';
import Modal from '../components/Modal.vue';

// Component map
const components = {
  LiveVueUIButton: Button,
  LiveVueUIModal: Modal,
};

/**
 * Register LiveVue UI components with a Vue app instance
 */
export function registerComponents(app: App): void {
  // Register each component
  Object.entries(components).forEach(([name, component]) => {
    app.component(name, component);
  });
}

/**
 * Setup function for LiveVue that registers all components
 */
export function setupLiveVueUI(app: App): void {
  registerComponents(app);
}

// Export components for direct usage
export {
  Button,
  Modal,
};

// Export components map
export default components; 
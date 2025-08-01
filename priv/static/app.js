import { h } from "vue";
/**
 * Initializes a Vue app with the given options and mounts it to the specified element.
 * It's a default implementation of the `setup` option, which can be overridden.
 * If you want to override it, simply provide your own implementation of the `setup` option.
 */
export const defaultSetup = ({ createApp, component, props, slots, plugin, el }) => {
    const app = createApp({ render: () => h(component, props, slots) });
    app.use(plugin);
    app.mount(el);
    return app;
};
export const migrateToLiveVueApp = (components, options = {}) => {
    if ("resolve" in components && "setup" in components) {
        return components;
    }
    else {
        console.warn("deprecation warning:\n\nInstead of passing components, use createLiveVue({resolve, setup})");
        return createLiveVue({
            resolve: (name) => {
                for (const [key, value] of Object.entries(components)) {
                    if (key.endsWith(`${name}.vue`) || key.endsWith(`${name}/index.vue`)) {
                        return value;
                    }
                }
            },
            setup: options.initializeApp,
        });
    }
};
const resolveComponent = async (component) => {
    if (typeof component === "function") {
        // it's an async component, let's try to load it
        component = await component();
    }
    else if (component instanceof Promise) {
        component = await component;
    }
    if (component && "default" in component) {
        // if there's a default export, use it
        component = component.default;
    }
    return component;
};
export const createLiveVue = ({ resolve, setup }) => {
    return {
        setup: setup || defaultSetup,
        resolve: async (path) => {
            let component = resolve(path);
            if (!component)
                throw new Error(`Component ${path} not found!`);
            return await resolveComponent(component);
        },
    };
};

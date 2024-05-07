// imported only in SSR, won't work in browser because of vue/server-renderer assuming node
import { createSSRApp, h } from "vue";
import { renderToString } from "vue/server-renderer";

function getSlots(slots) {
    const slotFunctions = {}
    for (const slotName in slots) {
        slotFunctions[slotName] = () => h('div', {innerHTML: slots[slotName]})
    }
    return slotFunctions
}

export function getRender(components) {
    return async function render(name, props, slots) {
        const component = components[name]

        if (!component) {
            throw new Error(`Component ${componentName} not found`)
        }

        const app = createSSRApp({ render: () => h(component, props, getSlots(slots)) })
        return await renderToString(app, {});
    }
}
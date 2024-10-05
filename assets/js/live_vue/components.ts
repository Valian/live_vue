import { type Component } from "vue"
import { flatMapKeys } from "./utils"

type ComponentOrComponentModule = Component | { default: Component }
type ComponentMap = Record<string, ComponentOrComponentModule | (() => Promise<ComponentOrComponentModule>)>

/**
 * Converts a path to an array with the full path and just the filename.
 * Does a bit of cleanup, eg removes .vue and /index.vue from the path.
 * @returns An array with the full path and the filename.
 */
const pathToFullPathAndFilename = (path: string): string[] => {
    path = path.replace("/index.vue", "").replace(".vue", "")
    // both full path and only filename
    return [path, path.split("/").slice(-1)[0]]
}

/**
 * Converts a path to a relative path.
 * @returns A relative path.
 */
const getRelativePath = (path: string): string => {
    if (path.includes("../../")) {
        // it's colocated with the LiveView, so path should be relative to lib/my_app_web
        return path.split("/").slice(4).join("/")
    } else {
        // it's in the current directory
        return path.replace("./", "")
    }
}

/**
 * Normalizes the components by converting the keys to full paths and filenames.
 * @returns A new object with the normalized components.
 */
export const normalizeComponents = (components: ComponentMap): ComponentMap =>
    flatMapKeys(components, key => pathToFullPathAndFilename(getRelativePath(key)))

/**
 * Gets the component from the components object.
 * Throws an error if the component is not found.
 *
 * @returns The component.
 */
export const getComponent = async (components: ComponentMap, componentName: string | null): Promise<any> => {
    if (!componentName) {
        throw new Error("Component name is required")
    }

    let component = components[componentName]

    if (!component) {
        const available = Object.keys(components).filter(key => !key.includes("Elixir.") && !key.includes("/"))
        throw new Error(`Component ${componentName} not found!\n\nAvailable components: \n${available.join("\n")}\n`)
    }

    if (typeof component === "function") {
        // it's an async component, let's try to load it
        component = await (component as () => Promise<Component | { default: Component }>)()
    } else if (component instanceof Promise) {
        component = await component
    }

    if (component && "default" in component) {
        // if there's a default export, use it
        component = component.default
    }

    return component
}

/**
 * Maps the values of an object using a callback function and returns a new object with the mapped values.
 * @returns A new object with the mapped values.
 */
export const mapValues = (object, cb) => Object.entries(object).reduce((acc, [key, value]) => {
    acc[key] = cb(value, key, object);
    return acc;
}, {});
/**
 * Flattens the keys of an object using a callback function and returns a new object with the flattened keys.
 * @returns A new object with the flattened keys.
 */
export const flatMapKeys = (object, cb) => Object.entries(object).reduce((acc, [key, value]) => {
    const newKeys = cb(key, value, object);
    for (const newKey of newKeys)
        acc[newKey] = value;
    return acc;
}, {});
/**
 * Finds a component by name or path suffix.
 * @returns The component if found, otherwise throws an error with a list of available components.
 */
export const findComponent = (components, name) => {
    // we're looking for a component by name or path suffix.
    for (const [key, value] of Object.entries(components)) {
        if (key.endsWith(`${name}.vue`) || key.endsWith(`${name}/index.vue`)) {
            return value;
        }
    }
    // a helpful message for the user
    const availableComponents = Object.keys(components)
        .map(key => key.replace("../../lib/", "").replace("/index.vue", "").replace(".vue", "").replace("./", ""))
        .filter(key => !key.startsWith("_build"))
        .join("\n");
    throw new Error(`Component '${name}' not found! Available components:\n\n${availableComponents}\n\n`);
};

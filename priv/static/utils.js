import { isProxy, isReactive, isRef, toRaw } from "vue";
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
export function deepToRaw(sourceObj) {
    const objectIterator = (input) => {
        if (Array.isArray(input)) {
            return input.map(item => objectIterator(item));
        }
        if (isRef(input) || isReactive(input) || isProxy(input)) {
            return objectIterator(toRaw(input));
        }
        if (input && typeof input === "object") {
            return Object.keys(input).reduce((acc, key) => {
                acc[key] = objectIterator(input[key]);
                return acc;
            }, {});
        }
        return input;
    };
    return objectIterator(sourceObj);
}
function assignArray(targetArray, sourceArray) {
    // Adjust the length of the target array to match the source array
    targetArray.length = sourceArray.length;
    sourceArray.forEach((item, index) => {
        if (typeof item === "object" && item !== null) {
            if (index in targetArray && targetArray[index] !== null && targetArray[index] !== undefined) {
                // Deep assign existing items
                deepAssign(targetArray[index], item);
            }
            else {
                // Create a new item if it doesn't exist in the target
                targetArray[index] = deepAssign(Array.isArray(item) ? [] : {}, item);
            }
        }
        else {
            // For primitive values, simply assign
            targetArray[index] = item;
        }
    });
}
function clearObject(targetObject) {
    if (Array.isArray(targetObject)) {
        targetObject.length = 0;
    }
    else {
        Object.values(targetObject).forEach(value => {
            clearObject(value);
        });
    }
}
function assignObject(targetObject, sourceObject) {
    Object.keys(sourceObject).forEach(key => {
        const sourceValue = toRaw(sourceObject[key]);
        targetObject[key] =
            typeof sourceValue === "object" && sourceValue !== null && targetObject !== null
                ? deepAssign(targetObject[key] ?? (Array.isArray(sourceValue) ? [] : {}), sourceValue)
                : sourceValue;
    });
    // Remove properties from target that are not in source
    Object.keys(targetObject).forEach(key => {
        if (!(key in sourceObject)) {
            clearObject(targetObject[key]);
        }
    });
}
export function deepAssign(target, source) {
    if (Array.isArray(source)) {
        assignArray(target, source);
    }
    else if (typeof source === "object" && source !== null) {
        assignObject(target, source);
    }
    else {
        target = source;
    }
    return target;
}
export function deepCopy(obj) {
    if (structuredClone) {
        return structuredClone(deepToRaw(obj));
    }
    else {
        return JSON.parse(JSON.stringify(obj));
    }
}
import { ref, computed } from "vue";
export const debounce = (func, wait) => {
    if (!wait || wait <= 0) {
        return {
            debouncedFn: func,
            isPending: computed(() => false),
        };
    }
    let timeout = null;
    let executingCount = 0;
    let pendingResolvers = [];
    const timeoutRef = ref(null);
    const executingCountRef = ref(0);
    const debouncedFn = (...args) => {
        return new Promise((resolve, reject) => {
            pendingResolvers.push({ resolve, reject });
            if (timeout !== null)
                clearTimeout(timeout);
            timeout = setTimeout(async () => {
                const currentResolvers = pendingResolvers;
                pendingResolvers = [];
                timeout = null;
                timeoutRef.value = null;
                executingCount++;
                executingCountRef.value++;
                try {
                    const result = await func(...args);
                    currentResolvers.forEach(({ resolve }) => resolve(result));
                }
                catch (error) {
                    currentResolvers.forEach(({ reject }) => reject(error));
                }
                finally {
                    executingCount--;
                    executingCountRef.value--;
                }
            }, wait);
            timeoutRef.value = timeout;
        });
    };
    const isPending = computed(() => timeoutRef.value !== null || executingCountRef.value > 0);
    return { debouncedFn, isPending };
};
export const cacheOnAccessProxy = (createFunc) => new Proxy({}, {
    // @ts-expect-error proxy get always expect string key
    get: (fields, key) => {
        if (typeof key === "string" && key.startsWith("__")) {
            return Reflect.get(fields, key);
        }
        if (!Reflect.has(fields, key)) {
            Reflect.set(fields, key, createFunc(key));
        }
        return Reflect.get(fields, key);
    },
});
/**
 * Parses a path string like "user.items[0].name" into an array of keys
 */
export function parsePath(path) {
    if (!path)
        return [];
    const keys = [];
    let current = "";
    let i = 0;
    while (i < path.length) {
        const char = path[i];
        if (char === ".") {
            if (current) {
                keys.push(current);
                current = "";
            }
        }
        else if (char === "[") {
            if (current) {
                keys.push(current);
                current = "";
            }
            // Find the closing bracket
            i++;
            let bracketContent = "";
            while (i < path.length && path[i] !== "]") {
                bracketContent += path[i];
                i++;
            }
            if (path[i] === "]") {
                const index = parseInt(bracketContent, 10);
                if (!isNaN(index)) {
                    keys.push(index);
                }
                else {
                    keys.push(bracketContent); // String key in brackets
                }
            }
        }
        else {
            current += char;
        }
        i++;
    }
    if (current) {
        keys.push(current);
    }
    return keys;
}
/**
 * Gets a value from an object using a parsed path
 */
export function getValueByPath(obj, keys) {
    let current = obj;
    for (const key of keys) {
        if (current == null)
            return undefined;
        current = current[key];
    }
    return current;
}
/**
 * Sets a value in an object using a parsed path
 */
export function setValueByPath(obj, keys, value) {
    if (keys.length === 0)
        return;
    let current = obj;
    for (let i = 0; i < keys.length - 1; i++) {
        const key = keys[i];
        if (current[key] == null) {
            // Create object or array based on next key type
            const nextKey = keys[i + 1];
            current[key] = typeof nextKey === "number" ? [] : {};
        }
        current = current[key];
    }
    const lastKey = keys[keys.length - 1];
    current[lastKey] = value;
}
/**
 * Deep clone utility - alias for existing deepCopy function for consistency
 */
export const deepClone = deepCopy;
/**
 * Helper function to replace reactive object contents while preserving reactivity
 */
export function replaceReactiveObject(target, source) {
    // Remove properties that exist in target but not in source
    for (const key in target) {
        if (!(key in source)) {
            delete target[key];
        }
    }
    // Recursively update/add properties from source
    for (const key in source) {
        if (typeof source[key] === "object" && source[key] !== null && !Array.isArray(source[key])) {
            // Handle nested objects
            if (!target[key] || typeof target[key] !== "object" || Array.isArray(target[key])) {
                target[key] = {};
            }
            replaceReactiveObject(target[key], source[key]);
        }
        else {
            // Handle primitive values and arrays
            target[key] = source[key];
        }
    }
}

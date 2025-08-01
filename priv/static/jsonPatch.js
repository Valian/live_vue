/*!
 * Simplified JSON Patch functionality extracted from https://github.com/Starcounter-Jack/JSON-Patch/blob/master/src/core.ts
 * (c) 2013-2021 Joachim Wester
 * MIT license
 */
// Helper functions
function deepClone(obj) {
    if (obj === null || typeof obj !== "object")
        return obj;
    if (obj instanceof Date)
        return new Date(obj.getTime());
    if (Array.isArray(obj))
        return obj.map(item => deepClone(item));
    const cloned = {};
    for (const key in obj) {
        if (obj.hasOwnProperty(key)) {
            cloned[key] = deepClone(obj[key]);
        }
    }
    return cloned;
}
function unescapePathComponent(path) {
    return path.replace(/~1/g, "/").replace(/~0/g, "~");
}
function areEquals(a, b) {
    if (a === b)
        return true;
    if (a && b && typeof a == "object" && typeof b == "object") {
        const arrA = Array.isArray(a);
        const arrB = Array.isArray(b);
        if (arrA && arrB) {
            const length = a.length;
            if (length != b.length)
                return false;
            for (let i = length; i-- !== 0;) {
                if (!areEquals(a[i], b[i]))
                    return false;
            }
            return true;
        }
        if (arrA != arrB)
            return false;
        const keys = Object.keys(a);
        const length = keys.length;
        if (length !== Object.keys(b).length)
            return false;
        for (let i = length; i-- !== 0;) {
            if (!b.hasOwnProperty(keys[i]))
                return false;
        }
        for (let i = length; i-- !== 0;) {
            const key = keys[i];
            if (!areEquals(a[key], b[key]))
                return false;
        }
        return true;
    }
    return a !== a && b !== b;
}
/**
 * Retrieves a value from a JSON document by a JSON pointer.
 */
export function getValueByPointer(document, pointer) {
    if (pointer === "")
        return document;
    const keys = pointer.split("/").slice(1); // remove empty first element
    let obj = document;
    for (const key of keys) {
        const unescapedKey = key.indexOf("~") !== -1 ? unescapePathComponent(key) : key;
        if (Array.isArray(obj)) {
            obj = obj[unescapedKey === "-" ? obj.length - 1 : parseInt(unescapedKey, 10)];
        }
        else {
            obj = obj[unescapedKey];
        }
    }
    return obj;
}
/**
 * Apply a single JSON Patch Operation on a JSON document in-place.
 * Modifies the original document to maintain Vue reactivity.
 */
export function applyOperation(document, operation) {
    // Handle root operations
    if (operation.path === "") {
        switch (operation.op) {
            case "add":
            case "replace":
                return operation.value;
            case "move":
            case "copy":
                return getValueByPointer(document, operation.from);
            case "test":
                return document; // Test always returns original document
            case "remove":
                return null;
        }
    }
    const keys = operation.path.split("/").slice(1); // remove empty first element
    let obj = document;
    // Navigate to parent object
    for (let i = 0; i < keys.length - 1; i++) {
        const key = keys[i].indexOf("~") !== -1 ? unescapePathComponent(keys[i]) : keys[i];
        if (Array.isArray(obj)) {
            obj = obj[key === "-" ? obj.length - 1 : parseInt(key, 10)];
        }
        else {
            obj = obj[key];
        }
    }
    // Apply operation on final key
    const finalKey = keys[keys.length - 1];
    const unescapedKey = finalKey.indexOf("~") !== -1 ? unescapePathComponent(finalKey) : finalKey;
    if (Array.isArray(obj)) {
        const index = unescapedKey === "-" ? obj.length : parseInt(unescapedKey, 10);
        switch (operation.op) {
            case "add":
                obj.splice(index, 0, operation.value);
                break;
            case "remove":
                obj.splice(index, 1);
                break;
            case "replace":
                obj[index] = operation.value;
                break;
            case "move":
                const moveValue = getValueByPointer(document, operation.from);
                applyOperation(document, { op: "remove", path: operation.from });
                obj.splice(index, 0, moveValue);
                break;
            case "copy":
                const copyValue = getValueByPointer(document, operation.from);
                obj.splice(index, 0, deepClone(copyValue));
                break;
            case "test":
                // Test operation - just return document unchanged
                break;
        }
    }
    else {
        switch (operation.op) {
            case "add":
            case "replace":
                obj[unescapedKey] = operation.value;
                break;
            case "remove":
                delete obj[unescapedKey];
                break;
            case "move":
                const moveValue = getValueByPointer(document, operation.from);
                applyOperation(document, { op: "remove", path: operation.from });
                obj[unescapedKey] = moveValue;
                break;
            case "copy":
                const copyValue = getValueByPointer(document, operation.from);
                obj[unescapedKey] = deepClone(copyValue);
                break;
            case "test":
                // Test operation - just return document unchanged
                break;
        }
    }
    return document;
}
/**
 * Apply a JSON-Patch sequence to a JSON document in-place.
 * Modifies the original document to maintain Vue reactivity.
 */
export function applyPatch(document, patch) {
    let result = document;
    for (const operation of patch) {
        result = applyOperation(result, operation);
    }
    return result;
}

import { ComponentMap, ComponentOrComponentPromise } from "./types.js";
/**
 * Maps the values of an object using a callback function and returns a new object with the mapped values.
 * @returns A new object with the mapped values.
 */
export declare const mapValues: <T, U>(object: Record<string, T>, cb: (value: T, key: string, object: Record<string, T>) => U) => Record<string, U>;
/**
 * Flattens the keys of an object using a callback function and returns a new object with the flattened keys.
 * @returns A new object with the flattened keys.
 */
export declare const flatMapKeys: <T>(object: Record<string, T>, cb: (key: string, value: any, object: Record<string, T>) => string[]) => Record<string, T>;
/**
 * Finds a component by name or path suffix.
 * @returns The component if found, otherwise throws an error with a list of available components.
 */
export declare const findComponent: (components: ComponentMap, name: string) => ComponentOrComponentPromise;
export declare function deepToRaw<T>(sourceObj: T): T;
export declare function deepAssign(target: any, source: any): any;
export declare function deepCopy<T>(obj: T): T;
import { type ComputedRef } from "vue";
export declare const debounce: <T extends (...args: any[]) => any>(func: T, wait?: number) => {
    debouncedFn: (...args: Parameters<T>) => Promise<Awaited<ReturnType<T>>>;
    isPending: ComputedRef<boolean>;
};
export declare const cacheOnAccessProxy: <T extends object>(createFunc: (key: keyof T) => any) => {};
/**
 * Parses a path string like "user.items[0].name" into an array of keys
 */
export declare function parsePath(path: string): (string | number)[];
/**
 * Gets a value from an object using a parsed path
 */
export declare function getValueByPath(obj: any, keys: (string | number)[]): any;
/**
 * Sets a value in an object using a parsed path
 */
export declare function setValueByPath(obj: any, keys: (string | number)[], value: any): void;
/**
 * Deep clone utility - alias for existing deepCopy function for consistency
 */
export declare const deepClone: typeof deepCopy;
/**
 * Helper function to replace reactive object contents while preserving reactivity
 */
export declare function replaceReactiveObject(target: any, source: any): void;

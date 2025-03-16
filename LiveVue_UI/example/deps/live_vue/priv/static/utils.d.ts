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

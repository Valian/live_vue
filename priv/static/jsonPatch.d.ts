/*!
 * Simplified JSON Patch functionality extracted from https://github.com/Starcounter-Jack/JSON-Patch/blob/master/src/core.ts
 * (c) 2013-2021 Joachim Wester
 * MIT license
 */
export type Operation = AddOperation | RemoveOperation | ReplaceOperation | MoveOperation | CopyOperation | TestOperation | UpsertOperation | LimitOperation;
export interface BaseOperation {
    path: string;
}
export interface AddOperation extends BaseOperation {
    op: "add";
    value: any;
}
export interface RemoveOperation extends BaseOperation {
    op: "remove";
}
export interface ReplaceOperation extends BaseOperation {
    op: "replace";
    value: any;
}
export interface MoveOperation extends BaseOperation {
    op: "move";
    from: string;
}
export interface CopyOperation extends BaseOperation {
    op: "copy";
    from: string;
}
export interface TestOperation extends BaseOperation {
    op: "test";
    value: any;
}
export interface UpsertOperation extends BaseOperation {
    op: "upsert";
    value: any;
}
export interface LimitOperation extends BaseOperation {
    op: "limit";
    value: number;
}
/**
 * Retrieves a value from a JSON document by a JSON pointer.
 */
export declare function getValueByPointer(document: any, pointer: string): any;
/**
 * Apply a single JSON Patch Operation on a JSON document in-place.
 * Modifies the original document to maintain Vue reactivity.
 */
export declare function applyOperation<T>(document: T, operation: Operation): T;
/**
 * Apply a JSON-Patch sequence to a JSON document in-place.
 * Modifies the original document to maintain Vue reactivity.
 */
export declare function applyPatch<T>(document: T, patch: ReadonlyArray<Operation>): T;

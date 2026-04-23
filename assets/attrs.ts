import { h } from "vue"
import { mapValues, fromUtf8Base64 } from "./utils.js"
import type { Operation } from "./jsonPatch.js"

export type SlotMap = Record<string, (slotProps?: Record<string, any>) => any>

/**
 * Parses the JSON object from the element's attribute and returns them as an object.
 */
export const getAttributeJson = (el: HTMLElement, attributeName: string): Record<string, any> | null => {
  const data = el.getAttribute(attributeName)
  return data ? JSON.parse(data) : null
}

/**
 * Parses the slots from the element's attributes and returns them as a record.
 * The slots are parsed from the "data-slots" attribute.
 * The slots are converted to a function that returns a div with the innerHTML set to the base64 decoded slot.
 */
export const getSlots = (el: HTMLElement): SlotMap => {
  const dataSlots = getAttributeJson(el, "data-slots") || {}
  return mapValues(dataSlots, base64 => () => h("div", { innerHTML: fromUtf8Base64(base64).trim() }))
}

export const getDiff = (el: HTMLElement, attributeName: string): Operation[] => {
  const dataPropsDiff = getAttributeJson(el, attributeName) || []
  return dataPropsDiff.map(([op, path, value]: [string, string, any]) => ({
    op,
    path,
    value,
  }))
}

/**
 * Parses the event handlers from the element's attributes and returns them as a record.
 * The handlers are parsed from the "data-handlers" attribute.
 * The handlers are converted to snake case and returned as a record.
 * A special case is made for the "JS.push" event, where the event is replaced with $event.
 */
export const getHandlers = (el: HTMLElement, liveSocket: any): Record<string, (event: any) => void> => {
  const handlers = getAttributeJson(el, "data-handlers") || {}
  const result: Record<string, (event: any) => void> = {}
  for (const handlerName in handlers) {
    const ops = handlers[handlerName]
    const snakeCaseName = `on${handlerName.charAt(0).toUpperCase() + handlerName.slice(1)}`
    result[snakeCaseName] = event => {
      // a little bit of magic to replace the event with the value of the input
      const parsedOps = JSON.parse(ops)
      const replacedOps = parsedOps.map(([op, args, ...other]: [string, any, ...any[]]) => {
        if (op === "push" && !args.value) args.value = event
        return [op, args, ...other]
      })
      liveSocket.execJS(el, JSON.stringify(replacedOps))
    }
  }
  return result
}

/**
 * Parses the props from the element's attributes and returns them as an object.
 * The props are parsed from the "data-props" attribute.
 * The props are merged with the event handlers from the "data-handlers" attribute.
 */
export const getProps = (el: HTMLElement, liveSocket: any): Record<string, any> => ({
  ...(getAttributeJson(el, "data-props") || {}),
  ...getHandlers(el, liveSocket),
})

export const getElementId = (el: HTMLElement): string | null => el.id || el.getAttribute("id")


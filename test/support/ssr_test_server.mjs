// Test SSR server for NodeJS SSR tests
// This is a minimal implementation that echoes back the component info

export function render(name, props, slots) {
  // Simulate the real SSR behavior
  if (name === "WithPreloadLinks") {
    return `<link rel="stylesheet" href="/app.css" /><!-- preload --><div class="ssr-rendered">${name}</div>`;
  }

  if (name === "Error") {
    throw new Error("Intentional test error");
  }

  // Default: return simple HTML
  const propsStr = JSON.stringify(props);
  const slotsStr = JSON.stringify(slots);
  return `<div data-component="${name}" data-props="${propsStr.replace(/"/g, '&quot;')}" data-slots="${slotsStr.replace(/"/g, '&quot;')}">SSR Rendered: ${name}</div>`;
}

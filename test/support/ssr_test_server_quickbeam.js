export function render(name, props, slots) {
  if (name === "WithPreloadLinks") {
    return '<link rel="stylesheet" href="/app.css" /><!-- preload --><div class="ssr-rendered">' + name + '</div>';
  }

  if (name === "Error") {
    throw new Error("Intentional test error");
  }

  var propsStr = JSON.stringify(props);
  var slotsStr = JSON.stringify(slots);
  return '<div data-component="' + name + '">' +
    'SSR Rendered: ' + name +
    ' Props: ' + propsStr +
    ' Slots: ' + slotsStr +
    '</div>';
}

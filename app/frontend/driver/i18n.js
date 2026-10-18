// Strings come from the Rails locale files (driver_app.*), rendered into the page in the driver's language.
let strings = {}

export function setStrings(value) {
  strings = value || {}
}

export function t(key, values = {}) {
  const text = key.split(".").reduce((node, part) => node?.[part], strings)
  if (typeof text !== "string") return key
  return text.replace(/%\{(\w+)\}/g, (_, name) => values[name] ?? "")
}

export function amd(amount) {
  return `${String(amount).replace(/\B(?=(\d{3})+(?!\d))/g, " ")} ֏`
}

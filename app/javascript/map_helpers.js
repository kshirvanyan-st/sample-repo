import * as maplibregl from "maplibre-gl"

export const YEREVAN = [ 44.5126, 40.1777 ] // [longitude, latitude]
export const COLORS = { pickup: "#16a34a", dropoff: "#dc2626", route: "#2563eb", zone: "#ca8a04" }

export function createMap(container, styleUrl, options = {}) {
  const map = new maplibregl.Map({ container, style: styleUrl, center: YEREVAN, zoom: 12, attributionControl: { compact: true }, ...options })
  map.addControl(new maplibregl.NavigationControl({ showCompass: false }), "top-right")
  return map
}

export function createMarker(kind) {
  return new maplibregl.Marker({ color: COLORS[kind] })
}

// Draws a GeoJSON geometry: a line for routes, a translucent fill for zones. Safe to call again.
export function drawGeometry(map, id, geometry, kind = "route") {
  const data = { type: "Feature", geometry, properties: {} }
  if (map.getSource(id)) return map.getSource(id).setData(data)

  map.addSource(id, { type: "geojson", data })
  if (kind === "zone") {
    map.addLayer({ id: `${id}-fill`, type: "fill", source: id, paint: { "fill-color": COLORS.zone, "fill-opacity": 0.12 } })
    map.addLayer({ id: `${id}-line`, type: "line", source: id, paint: { "line-color": COLORS.zone, "line-width": 2 } })
  } else {
    map.addLayer({ id, type: "line", source: id, layout: { "line-cap": "round", "line-join": "round" },
                   paint: { "line-color": COLORS.route, "line-width": 5 } })
  }
}

export function fitTo(map, coordinates, padding = 48) {
  if (coordinates.length === 0) return
  const bounds = coordinates.reduce((box, point) => box.extend(point), new maplibregl.LngLatBounds(coordinates[0], coordinates[0]))
  map.fitBounds(bounds, { padding, maxZoom: 15, duration: 0 })
}

// Every [lon, lat] pair in a GeoJSON geometry.
export function coordinatesOf(geometry) {
  const flatten = (value) => typeof value[0] === "number" ? [ value ] : value.flatMap(flatten)
  return geometry?.coordinates ? flatten(geometry.coordinates) : []
}

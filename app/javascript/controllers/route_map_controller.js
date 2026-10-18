import { Controller } from "@hotwired/stimulus"
import { createMap, createMarker, drawGeometry, fitTo, coordinatesOf } from "map_helpers"

// A read-only map: a route with pickup and drop-off pins, and/or a service zone outline.
export default class extends Controller {
  static values = { styleUrl: String, route: Object, pickup: Array, dropoff: Array, zone: Object }

  connect() {
    this.map = createMap(this.element, this.styleUrlValue, { interactive: true })
    this.map.on("load", () => {
      if (this.hasZoneValue && this.zoneValue.type) drawGeometry(this.map, "zone", this.zoneValue, "zone")
      if (this.hasRouteValue && this.routeValue.type) drawGeometry(this.map, "route", this.routeValue)
    })
    if (this.pickupValue.length) createMarker("pickup").setLngLat(this.pickupValue).addTo(this.map)
    if (this.dropoffValue.length) createMarker("dropoff").setLngLat(this.dropoffValue).addTo(this.map)
    fitTo(this.map, [ ...coordinatesOf(this.routeValue), ...coordinatesOf(this.zoneValue), this.pickupValue, this.dropoffValue ].filter((point) => point.length))
  }

  disconnect() {
    this.map?.remove()
  }
}

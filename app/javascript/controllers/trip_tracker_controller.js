import { Controller } from "@hotwired/stimulus"
import consumer from "cable"
import { createMap, createMarker, drawGeometry, fitTo, coordinatesOf } from "map_helpers"
import * as maplibregl from "maplibre-gl"

const CANCELLABLE = [ "searching", "accepted", "arrived" ]

// The rider's live map: route, pickup and destination pins, and the car moving as the driver drives.
export default class extends Controller {
  static targets = [ "map", "cancel" ]
  static values = { styleUrl: String, tripId: Number, route: Object, pickup: Array, dropoff: Array, car: Array, status: String }

  connect() {
    this.map = createMap(this.mapTarget, this.styleUrlValue)
    this.map.on("load", () => { if (this.routeValue.type) drawGeometry(this.map, "route", this.routeValue) })
    createMarker("pickup").setLngLat(this.pickupValue).addTo(this.map)
    createMarker("dropoff").setLngLat(this.dropoffValue).addTo(this.map)
    this.car = new maplibregl.Marker({ element: this.carElement() })
    if (this.carValue.length) this.moveCar(this.carValue)
    fitTo(this.map, [ ...coordinatesOf(this.routeValue), this.pickupValue, this.dropoffValue, ...(this.carValue.length ? [ this.carValue ] : []) ])

    this.subscription = consumer.subscriptions.create({ channel: "TripChannel", id: this.tripIdValue }, {
      received: (data) => this.received(data)
    })
  }

  disconnect() {
    this.subscription?.unsubscribe()
    this.map?.remove()
  }

  received(data) {
    if (data.type === "location") this.moveCar([ data.lon, data.lat ])
    if (data.type === "status") this.statusValue = data.status
  }

  statusValueChanged() {
    if (this.hasCancelTarget) this.cancelTarget.hidden = !CANCELLABLE.includes(this.statusValue)
    if (!CANCELLABLE.includes(this.statusValue) && this.statusValue !== "in_progress") this.car?.remove()
  }

  moveCar(lngLat) {
    this.car.setLngLat(lngLat).addTo(this.map)
  }

  carElement() {
    const element = document.createElement("div")
    element.textContent = "🚕"
    element.className = "text-3xl drop-shadow"
    element.setAttribute("aria-hidden", "true")
    return element
  }
}

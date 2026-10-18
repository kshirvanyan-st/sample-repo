import { Controller } from "@hotwired/stimulus"
import consumer from "cable"
import { createMap, createMarker, drawGeometry, fitTo, coordinatesOf } from "map_helpers"
import * as maplibregl from "maplibre-gl"
import { Turbo } from "@hotwired/turbo-rails"

const CANCELLABLE = [ "searching", "accepted", "arrived" ]
const ON_THE_WAY = [ "accepted", "arrived", "in_progress" ]

// The rider's live map: route, pickup and destination pins, and the car moving as the driver drives.
export default class extends Controller {
  static targets = [ "map", "cancel", "safety", "statusLabel" ]
  static values = { styleUrl: String, tripId: Number, token: String, channel: { type: String, default: "TripChannel" },
                    labels: Object, route: Object, pickup: Array, dropoff: Array, car: Array, status: String }

  connect() {
    this.map = createMap(this.mapTarget, this.styleUrlValue)
    this.map.on("load", () => { if (this.routeValue.type) drawGeometry(this.map, "route", this.routeValue) })
    createMarker("pickup").setLngLat(this.pickupValue).addTo(this.map)
    createMarker("dropoff").setLngLat(this.dropoffValue).addTo(this.map)
    this.car = new maplibregl.Marker({ element: this.carElement() })
    if (this.carValue.length) this.moveCar(this.carValue)
    fitTo(this.map, [ ...coordinatesOf(this.routeValue), this.pickupValue, this.dropoffValue, ...(this.carValue.length ? [ this.carValue ] : []) ])

    // The rider listens by trip id; the public shared-trip page by its link's token.
    const params = this.channelValue === "SharedTripChannel" ? { channel: this.channelValue, token: this.tokenValue } : { channel: this.channelValue, id: this.tripIdValue }
    this.subscription = consumer.subscriptions.create(params, {
      received: (data) => this.received(data)
    })
  }

  disconnect() {
    clearTimeout(this.panelCheck)
    this.subscription?.unsubscribe()
    this.map?.remove()
  }

  received(data) {
    if (data.type === "location") this.moveCar([ data.lon, data.lat ])
    if (data.type === "sync" && data.lat != null && CANCELLABLE.concat("in_progress").includes(data.status)) this.moveCar([ data.lon, data.lat ])
    if (data.type === "status" || data.type === "sync") {
      // The rating form needs a fresh page (forms can't come over the cable), so reload when the trip ends.
      if (data.status === "completed" && this.statusValue !== "completed" && this.channelValue === "TripChannel") return this.reload()
      this.statusValue = data.status
      this.checkPanel()
    }
  }

  // The status panel comes over its own Turbo stream, which may have subscribed a moment after a
  // change went out (e.g. the driver accepting right away). If it still shows an older status, reload.
  checkPanel() {
    if (this.channelValue !== "TripChannel") return
    clearTimeout(this.panelCheck)
    this.panelCheck = setTimeout(() => {
      const panel = document.getElementById("trip_status")
      if (panel && panel.dataset.status !== this.statusValue) this.reload()
    }, 1500)
  }

  reload() {
    Turbo.visit(window.location.href, { action: "replace" })
  }

  statusValueChanged() {
    if (this.hasCancelTarget) this.cancelTarget.hidden = !CANCELLABLE.includes(this.statusValue)
    if (this.hasSafetyTarget) this.safetyTarget.hidden = !ON_THE_WAY.includes(this.statusValue)
    if (this.hasStatusLabelTarget && this.labelsValue[this.statusValue]) this.statusLabelTarget.textContent = this.labelsValue[this.statusValue]
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

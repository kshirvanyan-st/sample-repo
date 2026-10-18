import { Controller } from "@hotwired/stimulus"
import { createMap, createMarker, fitTo } from "map_helpers"

// "Where to?" form: pick pickup and drop-off by address search, by tapping the map, from a saved
// place, or (pickup) from the phone's location. Fills the hidden lat/lon fields the form submits.
export default class extends Controller {
  static targets = [ "map", "results", "status", "submit",
                     "pickupQuery", "pickupLat", "pickupLon", "pickupAddress",
                     "dropoffQuery", "dropoffLat", "dropoffLon", "dropoffAddress" ]
  static values = { styleUrl: String, searchUrl: String, reverseUrl: String, labels: Object }

  connect() {
    this.active = this.hasPoint("pickup") ? "dropoff" : "pickup"
    this.markers = { pickup: createMarker("pickup"), dropoff: createMarker("dropoff") }
    this.map = createMap(this.mapTarget, this.styleUrlValue)
    this.map.on("click", (event) => this.pickOnMap(event.lngLat))
    for (const field of [ "pickup", "dropoff" ]) {
      if (this.hasPoint(field)) this.place(field, this.target(field, "Lat").value, this.target(field, "Lon").value)
    }
    this.fit()
    this.update()
  }

  disconnect() {
    this.map?.remove()
  }

  focus(event) {
    this.active = event.params.field
  }

  async search(event) {
    event.preventDefault()
    const field = event.params.field
    this.active = field
    const query = this.target(field, "Query").value.trim()
    if (query.length < 2) return

    this.say(this.labelsValue.searching)
    try {
      const places = await this.getJSON(this.searchUrlValue, { q: query })
      this.showResults(field, places)
      this.say(places.length ? "" : this.labelsValue.noResults)
    } catch {
      this.say(this.labelsValue.failed)
    }
  }

  // A search result or a saved place.
  choose(event) {
    const { lat, lon, name, address } = event.params
    const field = event.params.field || this.active
    this.set(field, lat, lon, name, address || name)
    this.resultsTarget.replaceChildren()
  }

  locate() {
    if (!navigator.geolocation) return this.say(this.labelsValue.noLocation)
    this.say(this.labelsValue.locating)
    navigator.geolocation.getCurrentPosition(
      (position) => this.pickPoint("pickup", position.coords.latitude, position.coords.longitude),
      () => this.say(this.labelsValue.noLocation),
      { enableHighAccuracy: true, timeout: 10000 })
  }

  pickOnMap(lngLat) {
    this.pickPoint(this.active, lngLat.lat, lngLat.lng)
  }

  // A point without a name: put the pin down now, then ask what's there.
  async pickPoint(field, lat, lon) {
    const fallback = `${lat.toFixed(5)}, ${lon.toFixed(5)}`
    this.set(field, lat, lon, fallback, fallback)
    try {
      const place = await this.getJSON(this.reverseUrlValue, { lat, lon })
      if (place.name && this.target(field, "Lat").value == lat) {
        this.target(field, "Query").value = place.name
        this.target(field, "Address").value = [ place.name, place.address ].filter(Boolean).join(", ")
      }
      this.say("")
    } catch {
      this.say("")
    }
  }

  set(field, lat, lon, label, address) {
    this.target(field, "Lat").value = lat
    this.target(field, "Lon").value = lon
    this.target(field, "Query").value = label
    this.target(field, "Address").value = address
    this.place(field, lat, lon)
    if (field === "pickup" && !this.hasPoint("dropoff")) this.active = "dropoff"
    this.fit()
    this.update()
  }

  place(field, lat, lon) {
    this.markers[field].setLngLat([ Number(lon), Number(lat) ]).addTo(this.map)
  }

  fit() {
    const points = [ "pickup", "dropoff" ].filter((field) => this.hasPoint(field))
      .map((field) => [ Number(this.target(field, "Lon").value), Number(this.target(field, "Lat").value) ])
    if (points.length === 1) this.map.jumpTo({ center: points[0], zoom: 15 })
    if (points.length === 2) fitTo(this.map, points)
  }

  update() {
    this.submitTarget.disabled = !(this.hasPoint("pickup") && this.hasPoint("dropoff"))
  }

  showResults(field, places) {
    const items = places.map((place) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "block w-full px-3 py-2 text-left hover:bg-gray-50"
      button.dataset.action = "trip-planner#choose"
      Object.entries({ field, lat: place.lat, lon: place.lon, name: place.name, address: [ place.name, place.address ].filter(Boolean).join(", ") })
        .forEach(([ key, value ]) => button.setAttribute(`data-trip-planner-${key}-param`, value))
      const name = document.createElement("span")
      name.className = "font-medium"
      name.textContent = place.name
      const address = document.createElement("span")
      address.className = "block text-sm text-gray-600"
      address.textContent = place.address || ""
      button.append(name, address)
      const item = document.createElement("li")
      item.append(button)
      return item
    })
    this.resultsTarget.replaceChildren(...items)
  }

  hasPoint(field) {
    return this.target(field, "Lat").value !== "" && this.target(field, "Lon").value !== ""
  }

  target(field, name) {
    return this[`${field}${name}Target`]
  }

  say(text) {
    this.statusTarget.textContent = text || ""
  }

  async getJSON(url, params) {
    const response = await fetch(`${url}?${new URLSearchParams(params)}`, { headers: { Accept: "application/json" } })
    if (!response.ok) throw new Error(response.status)
    return response.json()
  }
}

import { Controller } from "@hotwired/stimulus"

// Fills hidden latitude/longitude fields from the browser's location.
export default class extends Controller {
  static targets = [ "latitude", "longitude", "status" ]

  locate() {
    if (!("geolocation" in navigator)) {
      this.statusTarget.textContent = "Location isn't available in this browser."
      return
    }

    this.statusTarget.textContent = "Locating…"
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        this.latitudeTarget.value = coords.latitude.toFixed(6)
        this.longitudeTarget.value = coords.longitude.toFixed(6)
        this.statusTarget.textContent = "Location saved."
      },
      () => { this.statusTarget.textContent = "Couldn't get your location." }
    )
  }
}

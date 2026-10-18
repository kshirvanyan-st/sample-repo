import { Controller } from "@hotwired/stimulus"

const HOLD_MS = 1500

// Press and hold to confirm (SOS), so a stray tap in a pocket doesn't send an alarm. Adds the
// phone's location when it can get one quickly.
export default class extends Controller {
  static targets = [ "form", "progress", "lat", "lon" ]

  start(event) {
    event.preventDefault()
    if (this.timer) return
    this.locate()
    this.progressTarget.style.transition = `width ${HOLD_MS}ms linear`
    this.progressTarget.style.width = "100%"
    this.timer = setTimeout(() => this.formTarget.requestSubmit(), HOLD_MS)
  }

  cancel() {
    clearTimeout(this.timer)
    this.timer = null
    this.progressTarget.style.transition = "none"
    this.progressTarget.style.width = "0"
  }

  locate() {
    navigator.geolocation?.getCurrentPosition(({ coords }) => {
      this.latTarget.value = coords.latitude
      this.lonTarget.value = coords.longitude
    }, () => {}, { maximumAge: 30000, timeout: 1000 })
  }
}

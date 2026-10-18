import { Controller } from "@hotwired/stimulus"

// A gift that floats up over the video for a few seconds, then removes itself.
export default class extends Controller {
  connect() {
    this.element.animate(
      [ { opacity: 0, transform: "translate(-50%, 20px) scale(0.6)" },
        { opacity: 1, transform: "translate(-50%, -20px) scale(1.15)", offset: 0.2 },
        { opacity: 1, transform: "translate(-50%, -60px) scale(1)", offset: 0.8 },
        { opacity: 0, transform: "translate(-50%, -100px) scale(1)" } ],
      { duration: 3000, easing: "ease-out" }
    ).finished.then(() => this.element.remove())
  }
}

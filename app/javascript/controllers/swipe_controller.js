import { Controller } from "@hotwired/stimulus"

const THRESHOLD = 120

// Drag the card (or press ← / →) to skip or like. Submits the matching button form,
// so the plain buttons keep working without JavaScript.
export default class extends Controller {
  static targets = [ "card", "like", "skip", "superlike" ]

  start(event) {
    this.startX = event.clientX
    this.dx = 0
    this.cardTarget.setPointerCapture(event.pointerId)
    this.cardTarget.style.transition = "none"
  }

  move(event) {
    if (this.startX === undefined) return

    this.dx = event.clientX - this.startX
    this.cardTarget.style.transform = `translateX(${this.dx}px) rotate(${this.dx / 20}deg)`
  }

  end() {
    if (this.startX === undefined) return

    const dx = this.dx
    this.startX = undefined
    if (dx > THRESHOLD) this.rate("like", 1)
    else if (dx < -THRESHOLD) this.rate("skip", -1)
    else this.reset()
  }

  cancel() {
    this.startX = undefined
    this.reset()
  }

  key(event) {
    if (event.target.closest("input, textarea, select")) return

    if (event.key === "ArrowRight") this.rate("like", 1)
    if (event.key === "ArrowLeft") this.rate("skip", -1)
  }

  rate(kind, direction) {
    if (this.submitted) return

    this.submitted = true
    this.cardTarget.style.transition = "transform 200ms ease-out"
    this.cardTarget.style.transform = `translateX(${direction * window.innerWidth}px) rotate(${direction * 30}deg)`
    this[`${kind}Target`].requestSubmit()
  }

  reset() {
    this.cardTarget.style.transition = "transform 150ms ease-out"
    this.cardTarget.style.transform = ""
  }
}

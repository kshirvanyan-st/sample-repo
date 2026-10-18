import { Controller } from "@hotwired/stimulus"

// Star picker: lights up the stars up to the one chosen and shows the matching reason chips
// (what went wrong for 1–3 stars, what was good for 4–5).
export default class extends Controller {
  static targets = [ "star", "low", "high" ]

  choose(event) {
    const stars = Number(event.target.value)
    this.starTargets.forEach((star, index) => star.classList.toggle("text-yellow-400", index < stars))
    this.lowTarget.hidden = stars > 3
    this.highTarget.hidden = stars <= 3
    const hidden = stars > 3 ? this.lowTarget : this.highTarget
    hidden.querySelectorAll("input:checked").forEach((input) => { input.checked = false })
  }
}

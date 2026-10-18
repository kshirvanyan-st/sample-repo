import { Controller } from "@hotwired/stimulus"

// Admin → Support: beeps when an urgent ticket (SOS) arrives live.
export default class extends Controller {
  static targets = [ "list" ]

  // The queue refreshes itself (morphing) when tickets arrive; beep for urgent rows not seen before.
  listTargetConnected(list) {
    this.seen = new Set(this.urgentIds(list))
    this.observer = new MutationObserver(() => {
      const fresh = this.urgentIds(list).filter((id) => !this.seen.has(id))
      fresh.forEach((id) => this.seen.add(id))
      if (fresh.length) this.beep()
    })
    this.observer.observe(list, { childList: true, subtree: true })
  }

  urgentIds(list) {
    return [ ...list.querySelectorAll("tr[data-urgent=true]") ].map((row) => row.id)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  beep() {
    try {
      const audio = new AudioContext()
      const tone = audio.createOscillator()
      tone.frequency.value = 660
      tone.connect(audio.destination)
      tone.start()
      tone.stop(audio.currentTime + 0.6)
    } catch { /* the browser may block sound until the page is clicked */ }
  }
}

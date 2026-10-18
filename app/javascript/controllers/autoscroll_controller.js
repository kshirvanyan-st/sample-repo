import { Controller } from "@hotwired/stimulus"

// Keeps a scrolling list pinned to its newest item (live chat).
export default class extends Controller {
  connect() {
    this.observer = new MutationObserver(() => { this.element.scrollTop = this.element.scrollHeight })
    this.observer.observe(this.element, { childList: true })
    this.element.scrollTop = this.element.scrollHeight
  }

  disconnect() {
    this.observer.disconnect()
  }
}

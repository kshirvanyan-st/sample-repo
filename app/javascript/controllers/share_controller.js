import { Controller } from "@hotwired/stimulus"

// "Share trip": asks the server for the trip's link, then opens the phone's share sheet (Viber,
// WhatsApp…) or copies the link where sharing isn't available (or shows it, if copying isn't allowed).
export default class extends Controller {
  static values = { url: String, copied: String }

  async share() {
    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: { Accept: "application/json", "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content }
    })
    if (!response.ok) return
    const { url, text } = await response.json()
    if (navigator.share) {
      navigator.share({ url, text }).catch(() => {})
    } else {
      try {
        await navigator.clipboard.writeText(url)
        this.element.textContent = this.copiedValue
      } catch {
        window.prompt(text, url) // no clipboard access: show the link to copy by hand
      }
    }
  }
}

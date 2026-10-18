import { Controller } from "@hotwired/stimulus"

// Chat window: aligns your own messages to the right, keeps the view scrolled
// to the newest message, sends on Enter, and marks incoming messages as read.
// "Seen" is broadcast to both people, so it's only shown under your own last message.
export default class extends Controller {
  static targets = [ "message", "scroller", "receipt" ]
  static values = { currentUserId: Number, readUrl: String }

  connect() {
    this.scrollToBottom()
    // Messages present at page load are already marked read by the server.
    requestAnimationFrame(() => { this.live = true })
  }

  receiptTargetConnected(element) {
    this.receiptObserver = new MutationObserver(() => this.refreshReceipt())
    this.receiptObserver.observe(element, { childList: true, characterData: true, subtree: true })
    this.refreshReceipt()
  }

  receiptTargetDisconnected() {
    this.receiptObserver?.disconnect()
  }

  messageTargetConnected(element) {
    const mine = Number(element.dataset.senderId) === this.currentUserIdValue
    if (mine) {
      element.classList.add("justify-end")
      element.querySelector("[data-bubble]").classList.replace("bg-gray-100", "bg-pink-600")
      element.querySelector("[data-bubble]").classList.replace("text-gray-900", "text-white")
    }
    document.getElementById("empty_chat")?.remove()
    this.refreshReceipt()
    this.scrollToBottom()
    if (this.live && !mine) this.markRead()
  }

  submitOnEnter(event) {
    if (event.shiftKey || event.isComposing) return

    event.preventDefault()
    event.target.form.requestSubmit()
  }

  markRead() {
    const token = document.querySelector("meta[name='csrf-token']")?.content
    fetch(this.readUrlValue, { method: "PATCH", headers: { "X-CSRF-Token": token }, credentials: "same-origin" })
  }

  refreshReceipt() {
    if (!this.hasReceiptTarget) return

    const last = this.messageTargets.at(-1)
    const lastIsMine = last && Number(last.dataset.senderId) === this.currentUserIdValue
    this.receiptTarget.hidden = !lastIsMine
  }

  scrollToBottom() {
    if (this.hasScrollerTarget) this.scrollerTarget.scrollTop = this.scrollerTarget.scrollHeight
  }
}

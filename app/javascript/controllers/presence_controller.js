import { Controller } from "@hotwired/stimulus"
import { cable } from "@hotwired/turbo-rails"

// Counts this page as one viewer for as long as it's open.
export default class extends Controller {
  static values = { streamId: Number }

  async connect() {
    this.subscription = await cable.subscribeTo({ channel: "StreamPresenceChannel", stream_id: this.streamIdValue })
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }
}

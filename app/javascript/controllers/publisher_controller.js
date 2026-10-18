import { Controller } from "@hotwired/stimulus"
import { negotiate } from "lib/webrtc"

// Studio: streams the camera to MediaMTX over WHIP. MediaMTX asks Rails whether the
// stream key is valid, then tells Rails the stream is live.
export default class extends Controller {
  static targets = [ "preview", "start", "stop", "status" ]
  static values = { whipUrl: String, streamKey: String, iceServers: Array }

  disconnect() {
    this.stop()
  }

  async start() {
    this.startTarget.disabled = true
    try {
      this.status("Turning on your camera…")
      this.media = await navigator.mediaDevices.getUserMedia({
        video: { width: { ideal: 1280 }, height: { ideal: 720 }, frameRate: { ideal: 30 } },
        audio: true
      })
      this.previewTarget.srcObject = this.media

      this.status("Connecting…")
      this.pc = new RTCPeerConnection({ iceServers: this.iceServersValue })
      this.media.getTracks().forEach((track) => this.pc.addTransceiver(track, { direction: "sendonly" }))
      this.pc.addEventListener("connectionstatechange", () => this.connectionChanged())
      this.session = await negotiate(this.pc, this.whipUrlValue, { Authorization: `Bearer ${this.streamKeyValue}` })

      this.startTarget.hidden = true
      this.stopTarget.hidden = false
    } catch (error) {
      this.status(error.message)
      this.teardown()
      this.startTarget.disabled = false
    }
  }

  stop() {
    if (this.session) fetch(this.session, { method: "DELETE" }).catch(() => {})
    this.session = null
    this.teardown()
    if (this.hasStartTarget) {
      this.startTarget.hidden = false
      this.startTarget.disabled = false
      this.stopTarget.hidden = true
      this.status("Stopped.")
    }
  }

  connectionChanged() {
    const state = this.pc?.connectionState
    if (state === "connected") this.status("You're live!")
    if (state === "failed") this.status("Connection lost. Try starting again.")
  }

  teardown() {
    this.pc?.close()
    this.pc = null
    this.media?.getTracks().forEach((track) => track.stop())
    this.media = null
  }

  status(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }
}

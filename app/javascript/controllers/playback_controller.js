import { Controller } from "@hotwired/stimulus"
import { negotiate } from "lib/webrtc"

// Watch page: plays the stream over WebRTC (WHEP, under a second of delay) or low-latency
// HLS, as the server picks per stream (data-protocol), falling back to HLS if WebRTC fails.
// The <video> is swapped in and out when the stream goes live or ends.
export default class extends Controller {
  static targets = [ "video", "status", "unmute" ]
  static values = { whepUrl: String, hlsUrl: String, token: String, iceServers: Array }

  videoTargetConnected(video) {
    this.play(video)
  }

  videoTargetDisconnected() {
    this.teardown()
  }

  disconnect() {
    this.teardown()
  }

  async play(video) {
    if (video.dataset.protocol === "hls") return this.playHLS(video)

    try {
      await this.playWebRTC(video)
    } catch (error) {
      console.warn("WebRTC playback failed, falling back to HLS", error)
      await this.playHLS(video)
    }
  }

  async playWebRTC(video) {
    this.pc = new RTCPeerConnection({ iceServers: this.iceServersValue })
    this.pc.addTransceiver("video", { direction: "recvonly" })
    this.pc.addTransceiver("audio", { direction: "recvonly" })
    this.pc.addEventListener("track", (event) => {
      if (video.srcObject !== event.streams[0]) video.srcObject = event.streams[0]
    })
    this.pc.addEventListener("connectionstatechange", () => {
      if (this.pc?.connectionState === "connected") this.status("")
    })
    await negotiate(this.pc, this.urlWithToken(this.whepUrlValue))
  }

  async playHLS(video) {
    this.teardown()
    const { default: Hls } = await import("hls.js")
    if (!Hls.isSupported()) {
      video.src = this.urlWithToken(this.hlsUrlValue) // Safari plays HLS natively
      return this.status("")
    }

    this.hls = new Hls({
      lowLatencyMode: true,
      // Every playlist and segment request needs the viewer token.
      xhrSetup: (xhr, url) => xhr.open("GET", this.urlWithToken(url), true)
    })
    this.hls.on(Hls.Events.MANIFEST_PARSED, () => this.status(""))
    this.hls.on(Hls.Events.ERROR, (_event, data) => { if (data.fatal) this.status("Couldn't load the stream.") })
    this.hls.loadSource(this.urlWithToken(this.hlsUrlValue))
    this.hls.attachMedia(video)
  }

  unmute() {
    if (!this.hasVideoTarget) return

    this.videoTarget.muted = false
    this.videoTarget.play()
    this.unmuteTarget.hidden = true
  }

  urlWithToken(url) {
    const parsed = new URL(url, window.location.href)
    parsed.searchParams.set("token", this.tokenValue)
    return parsed.toString()
  }

  teardown() {
    this.pc?.close()
    this.pc = null
    this.hls?.destroy()
    this.hls = null
  }

  status(text) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text
  }
}

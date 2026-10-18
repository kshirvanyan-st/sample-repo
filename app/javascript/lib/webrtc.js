// Minimal WHIP (RFC 9725) / WHEP signaling:
// POST our SDP offer, get the answer back. ICE candidates are gathered up front
// (no trickle) which keeps the exchange to a single request.
export async function negotiate(pc, url, headers = {}) {
  await pc.setLocalDescription(await pc.createOffer())
  await gatheringComplete(pc)

  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/sdp", ...headers },
    body: pc.localDescription.sdp
  })
  if (!response.ok) throw new Error(`Media server refused the connection (${response.status})`)

  await pc.setRemoteDescription({ type: "answer", sdp: await response.text() })
  const location = response.headers.get("Location")
  return location ? new URL(location, url).toString() : null
}

function gatheringComplete(pc, timeout = 2000) {
  if (pc.iceGatheringState === "complete") return Promise.resolve()

  return new Promise((resolve) => {
    const done = () => { pc.removeEventListener("icegatheringstatechange", check); resolve() }
    const check = () => { if (pc.iceGatheringState === "complete") done() }
    pc.addEventListener("icegatheringstatechange", check)
    setTimeout(done, timeout)
  })
}

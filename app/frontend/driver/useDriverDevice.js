import { useEffect, useRef, useState } from "react"
import { createConsumer } from "@rails/actioncable"

const SEND_EVERY_MS = 4000

// While online: watch GPS and send the position over DriverChannel every few seconds, keep the
// screen on (Wake Lock), and notice when the app is hidden (browsers pause GPS in the background).
// Always: listen for "refresh" nudges from the server.
export function useDriverDevice({ online, onRefresh }) {
  const [ hidden, setHidden ] = useState(document.visibilityState === "hidden")
  const [ gpsError, setGpsError ] = useState(null)
  const channel = useRef(null)
  const latest = useRef(null)
  const refresh = useRef(onRefresh)
  refresh.current = onRefresh

  useEffect(() => {
    const consumer = createConsumer()
    channel.current = consumer.subscriptions.create("DriverChannel", {
      received: (data) => { if (data.type === "refresh") refresh.current() },
      connected: () => refresh.current()
    })
    return () => consumer.disconnect()
  }, [])

  useEffect(() => {
    const onVisibility = () => {
      setHidden(document.visibilityState === "hidden")
      if (document.visibilityState === "visible") refresh.current()
    }
    document.addEventListener("visibilitychange", onVisibility)
    return () => document.removeEventListener("visibilitychange", onVisibility)
  }, [])

  useEffect(() => {
    if (!online || !navigator.geolocation) return

    const send = () => latest.current && channel.current?.perform("location", latest.current)
    const watch = navigator.geolocation.watchPosition(
      ({ coords }) => {
        const first = !latest.current
        latest.current = { lat: coords.latitude, lon: coords.longitude, heading: coords.heading, speed: coords.speed }
        setGpsError(null)
        if (first) send()
      },
      (error) => setGpsError(error.message),
      { enableHighAccuracy: true, maximumAge: 2000, timeout: 15000 })
    const timer = setInterval(send, SEND_EVERY_MS)

    let lock = null
    const keepAwake = () => navigator.wakeLock?.request("screen").then((value) => { lock = value }).catch(() => {})
    keepAwake()
    document.addEventListener("visibilitychange", keepAwake)

    return () => {
      navigator.geolocation.clearWatch(watch)
      clearInterval(timer)
      document.removeEventListener("visibilitychange", keepAwake)
      lock?.release()
      latest.current = null
    }
  }, [ online ])

  return { hidden, gpsError }
}

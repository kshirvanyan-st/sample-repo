import { useEffect, useState } from "react"

// Whole seconds left until an ISO time, ticking every 250 ms.
export function useCountdown(until) {
  const left = () => Math.max(0, Math.ceil((new Date(until) - Date.now()) / 1000))
  const [ seconds, setSeconds ] = useState(left)

  useEffect(() => {
    setSeconds(left())
    const timer = setInterval(() => setSeconds(left()), 250)
    return () => clearInterval(timer)
  }, [ until ])

  return seconds
}

import { useRef, useState } from "react"
import { t } from "../i18n"

export const HOLD_MS = 1500

// Press and hold for HOLD_MS to alert support (so a tap by accident doesn't), plus a direct 911 call.
export default function SosButton({ onSos }) {
  const timer = useRef(null)
  const [ holding, setHolding ] = useState(false)

  const start = () => {
    if (timer.current) return
    setHolding(true)
    timer.current = setTimeout(() => { timer.current = null; setHolding(false); onSos() }, HOLD_MS)
  }
  const stop = () => {
    clearTimeout(timer.current)
    timer.current = null
    setHolding(false)
  }

  return (
    <div className="mt-4 grid grid-cols-2 gap-3">
      <button type="button" onPointerDown={start} onPointerUp={stop} onPointerLeave={stop}
              className={`rounded-xl py-3 font-bold text-white ${holding ? "bg-red-800" : "bg-red-600"}`}>{t("sos.hold")}</button>
      <a href="tel:911" className="rounded-xl border-2 border-red-600 py-3 text-center font-bold text-red-700">{t("sos.call")}</a>
    </div>
  )
}

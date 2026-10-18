import { useEffect } from "react"
import { useCountdown } from "../useCountdown"
import { t, amd } from "../i18n"

function beep() {
  try {
    const audio = new AudioContext()
    const tone = audio.createOscillator()
    tone.frequency.value = 880
    tone.connect(audio.destination)
    tone.start()
    tone.stop(audio.currentTime + 0.3)
  } catch { /* no sound allowed yet */ }
}

export default function OfferCard({ offer, onAccept, onDecline, busy }) {
  const seconds = useCountdown(offer.expires_at)
  useEffect(() => { beep(); navigator.vibrate?.([ 200, 100, 200 ]) }, [ offer.id ])

  return (
    <section className="rounded-2xl bg-white p-5 text-gray-900" aria-live="assertive" aria-label={t("offer.title")}>
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold">{t("offer.title")}</h2>
        <span className="rounded-full bg-yellow-400 px-3 py-1 text-lg font-bold tabular-nums" role="timer" aria-label={t("offer.seconds_left", { seconds })}>
          {seconds}
        </span>
      </div>
      <p className="mt-3 text-3xl font-bold">{amd(offer.fare)}</p>
      <p className="mt-1 text-gray-600">{t("offer.summary", { eta: offer.eta_min ?? "?", km: offer.distance_km })}</p>
      <dl className="mt-4 space-y-2">
        <div><dt className="text-xs uppercase text-gray-500">{t("pickup")}</dt><dd className="font-medium">{offer.pickup.address || t("pin")}</dd></div>
        <div><dt className="text-xs uppercase text-gray-500">{t("dropoff")}</dt><dd className="font-medium">{offer.dropoff.address || t("pin")}</dd></div>
      </dl>
      <div className="mt-5 grid grid-cols-3 gap-3">
        <button type="button" className="rounded-xl border-2 border-gray-300 py-4 text-lg" onClick={onDecline} disabled={busy}>{t("offer.decline")}</button>
        <button type="button" className="col-span-2 rounded-xl bg-green-600 py-4 text-xl font-bold text-white disabled:opacity-60"
                onClick={onAccept} disabled={busy || seconds === 0}>{t("offer.accept")}</button>
      </div>
    </section>
  )
}

import { t } from "../i18n"

// After a trip: one tap to rate the rider, or skip.
export default function RateRiderCard({ trip, onRate, onSkip, busy }) {
  return (
    <section className="rounded-2xl bg-white p-5 text-gray-900" aria-label={t("rate.title", { name: trip.rider })}>
      <h2 className="text-lg font-bold">{t("rate.title", { name: trip.rider })}</h2>
      <div className="mt-3 flex justify-between">
        {[ 1, 2, 3, 4, 5 ].map((stars) => (
          <button key={stars} type="button" disabled={busy} onClick={() => onRate(stars)}
                  className="text-4xl text-yellow-400 disabled:opacity-60" aria-label={t("rate.stars", { stars })}>★</button>
        ))}
      </div>
      <button type="button" className="mt-3 text-sm underline" onClick={onSkip}>{t("rate.skip")}</button>
    </section>
  )
}

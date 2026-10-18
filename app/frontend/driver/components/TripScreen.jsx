import { t, amd } from "../i18n"

const NEXT = {
  accepted: { action: "arrive", label: "trip.arrived" },
  arrived: { action: "start", label: "trip.start" },
  in_progress: { action: "complete", label: "trip.complete" }
}

// Opens Yandex Navigator or Google Maps with directions to a point.
export function navigationLinks({ lat, lon }) {
  return {
    yandex: `yandexnavi://build_route_on_map?lat_to=${lat}&lon_to=${lon}`,
    google: `https://www.google.com/maps/dir/?api=1&destination=${lat},${lon}&travelmode=driving`
  }
}

export default function TripScreen({ trip, onAction, busy }) {
  const target = trip.status === "in_progress" ? trip.dropoff : trip.pickup
  const next = NEXT[trip.status]
  const links = navigationLinks(target)

  return (
    <section className="rounded-2xl bg-white p-5 text-gray-900">
      <p className="text-sm uppercase text-gray-500">{t(`trip.status.${trip.status}`)}</p>
      <h2 className="mt-1 text-xl font-bold">{target.address || t("pin")}</h2>
      <p className="mt-1 text-gray-600">{t("trip.rider", { name: trip.rider })} · {amd(trip.fare)}</p>
      <div className="mt-4 grid grid-cols-2 gap-3">
        <a className="rounded-xl border-2 border-gray-300 py-3 text-center" href={links.yandex}>{t("trip.navigate_yandex")}</a>
        <a className="rounded-xl border-2 border-gray-300 py-3 text-center" href={links.google} target="_blank" rel="noreferrer">{t("trip.navigate_google")}</a>
      </div>
      {next && (
        <button type="button" className="mt-4 w-full rounded-xl bg-yellow-400 py-5 text-xl font-bold disabled:opacity-60"
                onClick={() => onAction(next.action)} disabled={busy}>{t(next.label)}</button>
      )}
      {trip.status !== "in_progress" && (
        <button type="button" className="mt-3 w-full py-2 text-sm text-red-700 underline" onClick={() => onAction("cancel")} disabled={busy}>
          {t("trip.hand_back")}
        </button>
      )}
    </section>
  )
}

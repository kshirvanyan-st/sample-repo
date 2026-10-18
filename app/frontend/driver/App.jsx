import { useCallback, useEffect, useState } from "react"
import { api } from "./api"
import { t } from "./i18n"
import { useDriverDevice } from "./useDriverDevice"
import OfferCard from "./components/OfferCard"
import TripScreen from "./components/TripScreen"

export default function App({ stateUrl }) {
  const [ state, setState ] = useState(null)
  const [ busy, setBusy ] = useState(false)
  const [ error, setError ] = useState(null)

  const refresh = useCallback(() => api.state(stateUrl).then(setState).catch((e) => setError(e.message)), [ stateUrl ])
  useEffect(() => { refresh() }, [ refresh ])
  const { hidden, gpsError } = useDriverDevice({ online: !!state?.online, onRefresh: refresh })

  const run = async (call) => {
    setBusy(true)
    setError(null)
    try {
      setState(await call())
    } catch (e) {
      setError(e.message)
      refresh()
    } finally {
      setBusy(false)
    }
  }

  if (!state) return <p className="p-6">{t("loading")}</p>

  return (
    <main className="mx-auto flex min-h-screen max-w-md flex-col gap-4 p-4">
      <header className="flex items-center justify-between">
        <div>
          <p className="text-lg font-bold text-yellow-400">{t("title")}</p>
          <p className="text-sm text-gray-400">{state.name}{state.vehicle && ` · ${state.vehicle.plate}`}</p>
        </div>
        {!state.trip && (
          <button type="button" role="switch" aria-checked={state.online} disabled={busy}
                  className={`rounded-full px-5 py-3 text-lg font-bold ${state.online ? "bg-green-600" : "bg-gray-700"}`}
                  onClick={() => run(state.online ? api.offline : api.online)}>
            {state.online ? t("online") : t("offline")}
          </button>
        )}
      </header>

      {error && <p role="alert" className="rounded-lg bg-red-600 px-4 py-3">{error}</p>}
      {state.online && hidden && <p role="alert" className="rounded-lg bg-amber-500 px-4 py-3 text-gray-900">{t("keep_open")}</p>}
      {state.online && gpsError && <p role="alert" className="rounded-lg bg-amber-500 px-4 py-3 text-gray-900">{t("gps_error")}</p>}

      {state.trip ? (
        <TripScreen trip={state.trip} busy={busy} onAction={(action) => run(() => api.trip(state.trip.id, action))} />
      ) : state.offer ? (
        <OfferCard offer={state.offer} busy={busy} onAccept={() => run(() => api.accept(state.offer.id))} onDecline={() => run(() => api.decline(state.offer.id))} />
      ) : (
        <p className="mt-10 text-center text-xl text-gray-300">{state.online ? t("waiting") : t("go_online_hint")}</p>
      )}
    </main>
  )
}

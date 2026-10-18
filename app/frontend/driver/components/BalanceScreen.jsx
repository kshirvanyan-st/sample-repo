import { useEffect, useState } from "react"
import { api } from "../api"
import { t, amd } from "../i18n"

export const TOP_UP_AMOUNTS = [ 2000, 5000, 10000 ]

// Balance, what's needed to go online, today's numbers, recent lines, and top-up buttons.
export default function BalanceScreen({ onClose, load = api.wallet, topUp = api.topUp, go = (url) => window.location.assign(url) }) {
  const [ wallet, setWallet ] = useState(null)
  const [ error, setError ] = useState(null)
  const [ busy, setBusy ] = useState(false)

  useEffect(() => { load().then(setWallet).catch((e) => setError(e.message)) }, [ load ])

  const startTopUp = async (amount) => {
    setBusy(true)
    try {
      go((await topUp(amount)).checkout_url)
    } catch (e) {
      setError(e.message)
      setBusy(false)
    }
  }

  if (!wallet) return <p className="p-4">{error || t("loading")}</p>

  return (
    <section className="rounded-2xl bg-white p-5 text-gray-900" aria-label={t("balance.title")}>
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold">{t("balance.title")}</h2>
        <button type="button" className="text-sm underline" onClick={onClose}>{t("balance.close")}</button>
      </div>
      <p className={`mt-3 text-4xl font-bold tabular-nums ${wallet.balance < 0 ? "text-red-700" : ""}`}>{amd(wallet.balance)}</p>
      {wallet.needed > 0 && <p role="alert" className="mt-2 rounded-lg bg-amber-100 px-3 py-2 text-amber-900">{t("balance.needed", { amount: amd(wallet.needed) })}</p>}
      <p className="mt-2 text-sm text-gray-600">{t("balance.rules", { percent: wallet.commission_percent, min: amd(wallet.min_balance) })}</p>

      <h3 className="mt-5 font-semibold">{t("balance.today")}</h3>
      <dl className="mt-2 grid grid-cols-2 gap-2 text-sm">
        <dt className="text-gray-600">{t("balance.trips")}</dt><dd className="text-right">{wallet.today.trips}</dd>
        <dt className="text-gray-600">{t("balance.cash")}</dt><dd className="text-right">{amd(wallet.today.cash)}</dd>
        <dt className="text-gray-600">{t("balance.commission")}</dt><dd className="text-right">{amd(wallet.today.commission)}</dd>
        <dt className="text-gray-600">{t("balance.payouts")}</dt><dd className="text-right">{amd(wallet.today.payouts)}</dd>
      </dl>

      {wallet.top_ups ? (
        <div className="mt-5">
          <h3 className="font-semibold">{t("balance.top_up")}</h3>
          <div className="mt-2 grid grid-cols-3 gap-2">
            {TOP_UP_AMOUNTS.map((amount) => (
              <button key={amount} type="button" disabled={busy} onClick={() => startTopUp(amount)}
                      className="rounded-xl bg-yellow-400 py-3 font-bold disabled:opacity-60">{amd(amount)}</button>
            ))}
          </div>
        </div>
      ) : <p className="mt-5 text-sm text-gray-600">{t("balance.office_only")}</p>}
      {error && <p role="alert" className="mt-3 text-red-700">{error}</p>}

      {wallet.entries.length > 0 && (
        <ul className="mt-5 divide-y text-sm">
          {wallet.entries.map((entry) => (
            <li key={entry.id} className="flex justify-between py-2">
              <span>{t(`balance.kinds.${entry.kind}`)}</span>
              <span className={`tabular-nums ${entry.amount < 0 ? "text-red-700" : "text-green-700"}`}>{amd(entry.amount)}</span>
            </li>
          ))}
        </ul>
      )}
    </section>
  )
}

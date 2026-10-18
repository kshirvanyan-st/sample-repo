import { describe, it, expect, vi, beforeEach } from "vitest"
import { render, screen, fireEvent, waitFor } from "@testing-library/react"
import BalanceScreen from "./BalanceScreen"
import { setStrings } from "../i18n"

const wallet = (overrides = {}) => ({
  balance: -2500, min_balance: -2000, needed: 500, commission_percent: 10, top_ups: true,
  today: { trips: 3, cash: 4200, commission: 420, payouts: 0 },
  entries: [ { id: 1, kind: "commission", amount: -120, balance_after: -2500, at: "2026-10-18T10:00:00Z" } ],
  ...overrides
})

describe("BalanceScreen", () => {
  beforeEach(() => setStrings({ balance: { title: "Balance", needed: "Top up %{amount} to go online", top_up: "Top up", kinds: { commission: "Commission" }, office_only: "Pay at the office" } }))

  it("shows the balance, what's needed and the latest lines", async () => {
    render(<BalanceScreen load={() => Promise.resolve(wallet())} onClose={() => {}} />)
    expect(await screen.findByText("-2 500 ֏")).toBeTruthy()
    expect(screen.getByRole("alert").textContent).toBe("Top up 500 ֏ to go online")
    expect(screen.getByText("Commission")).toBeTruthy()
  })

  it("starts a top-up and goes to the payment page", async () => {
    const topUp = vi.fn().mockResolvedValue({ checkout_url: "/payments/sandbox/9" })
    const go = vi.fn()
    render(<BalanceScreen load={() => Promise.resolve(wallet())} topUp={topUp} go={go} onClose={() => {}} />)
    fireEvent.click(await screen.findByText("5 000 ֏"))
    await waitFor(() => expect(go).toHaveBeenCalledWith("/payments/sandbox/9"))
    expect(topUp).toHaveBeenCalledWith(5000)
  })

  it("points to the office when online top-ups are off", async () => {
    render(<BalanceScreen load={() => Promise.resolve(wallet({ top_ups: false, needed: 0 }))} onClose={() => {}} />)
    expect(await screen.findByText("Pay at the office")).toBeTruthy()
    expect(screen.queryByText("5 000 ֏")).toBeNull()
  })
})

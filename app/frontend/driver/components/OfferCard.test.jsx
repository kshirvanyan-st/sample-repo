import { describe, it, expect, vi, beforeEach, afterEach } from "vitest"
import { render, screen, fireEvent, act } from "@testing-library/react"
import OfferCard from "./OfferCard"
import { setStrings } from "../i18n"

const offer = (seconds) => ({
  id: 1, expires_at: new Date(Date.now() + seconds * 1000).toISOString(), fare: 1250, eta_min: 4, distance_km: 3.2,
  pickup: { lat: 40.17, lon: 44.51, address: "Republic Square" }, dropoff: { lat: 40.19, lon: 44.52, address: "Cascade" }
})

describe("OfferCard", () => {
  beforeEach(() => {
    vi.useFakeTimers()
    setStrings({ offer: { title: "New ride", accept: "Accept", decline: "Skip", summary: "%{eta} min away · %{km} km", seconds_left: "%{seconds} s" }, pickup: "From", dropoff: "To" })
  })
  afterEach(() => vi.useRealTimers())

  it("shows the price, the places and a countdown", () => {
    render(<OfferCard offer={offer(15)} onAccept={() => {}} onDecline={() => {}} />)
    expect(screen.getByText("1 250 ֏")).toBeTruthy()
    expect(screen.getByText("Republic Square")).toBeTruthy()
    expect(screen.getByRole("timer").textContent).toBe("15")
    act(() => { vi.advanceTimersByTime(5000) })
    expect(screen.getByRole("timer").textContent).toBe("10")
  })

  it("accepts while there is time, and not after", () => {
    const onAccept = vi.fn()
    render(<OfferCard offer={offer(2)} onAccept={onAccept} onDecline={() => {}} />)
    fireEvent.click(screen.getByText("Accept"))
    expect(onAccept).toHaveBeenCalledTimes(1)
    act(() => { vi.advanceTimersByTime(3000) })
    expect(screen.getByText("Accept").disabled).toBe(true)
  })
})

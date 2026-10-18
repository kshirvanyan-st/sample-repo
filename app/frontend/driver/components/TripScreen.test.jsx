import { describe, it, expect, vi, beforeEach } from "vitest"
import { render, screen, fireEvent } from "@testing-library/react"
import TripScreen, { navigationLinks } from "./TripScreen"
import { setStrings } from "../i18n"

const trip = (status) => ({
  id: 7, status, fare: 900, rider: "Ani",
  pickup: { lat: 40.17, lon: 44.51, address: "Republic Square" }, dropoff: { lat: 40.19, lon: 44.52, address: "Cascade" }
})

describe("TripScreen", () => {
  beforeEach(() => setStrings({ trip: { arrived: "I'm here", start: "Start", complete: "Finish", hand_back: "Hand back", rider: "Rider %{name}", status: {} } }))

  it.each([
    [ "accepted", "I'm here", "arrive", "Republic Square" ],
    [ "arrived", "Start", "start", "Republic Square" ],
    [ "in_progress", "Finish", "complete", "Cascade" ]
  ])("when %s, offers %s and heads to the right place", (status, label, action, place) => {
    const onAction = vi.fn()
    render(<TripScreen trip={trip(status)} onAction={onAction} />)
    expect(screen.getByRole("heading").textContent).toBe(place)
    fireEvent.click(screen.getByText(label))
    expect(onAction).toHaveBeenCalledWith(action)
  })

  it("can't hand back a trip that has started", () => {
    render(<TripScreen trip={trip("in_progress")} onAction={() => {}} />)
    expect(screen.queryByText("Hand back")).toBeNull()
  })

  it("builds navigation links", () => {
    expect(navigationLinks({ lat: 40.1, lon: 44.5 }).google).toContain("destination=40.1,44.5")
  })
})

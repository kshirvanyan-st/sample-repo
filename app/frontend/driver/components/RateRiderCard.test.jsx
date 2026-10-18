import { describe, it, expect, vi, beforeEach } from "vitest"
import { render, screen, fireEvent } from "@testing-library/react"
import RateRiderCard from "./RateRiderCard"
import { setStrings } from "../i18n"

describe("RateRiderCard", () => {
  beforeEach(() => setStrings({ rate: { title: "Rate %{name}", stars: "%{stars} stars", skip: "Skip" } }))

  it("rates with one tap or skips", () => {
    const onRate = vi.fn()
    const onSkip = vi.fn()
    render(<RateRiderCard trip={{ id: 3, rider: "Ani" }} onRate={onRate} onSkip={onSkip} />)
    expect(screen.getByRole("heading").textContent).toBe("Rate Ani")
    fireEvent.click(screen.getByLabelText("4 stars"))
    expect(onRate).toHaveBeenCalledWith(4)
    fireEvent.click(screen.getByText("Skip"))
    expect(onSkip).toHaveBeenCalled()
  })
})

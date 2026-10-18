import { describe, it, expect, vi, beforeEach, afterEach } from "vitest"
import { render, screen, fireEvent, act } from "@testing-library/react"
import SosButton, { HOLD_MS } from "./SosButton"
import { setStrings } from "../i18n"

describe("SosButton", () => {
  beforeEach(() => { vi.useFakeTimers(); setStrings({ sos: { hold: "Hold for SOS", call: "Call 911" } }) })
  afterEach(() => vi.useRealTimers())

  it("only alerts after a long press", () => {
    const onSos = vi.fn()
    render(<SosButton onSos={onSos} />)
    const button = screen.getByText("Hold for SOS")

    fireEvent.pointerDown(button)
    act(() => { vi.advanceTimersByTime(HOLD_MS / 2) })
    fireEvent.pointerUp(button)
    act(() => { vi.advanceTimersByTime(HOLD_MS) })
    expect(onSos).not.toHaveBeenCalled()

    fireEvent.pointerDown(button)
    act(() => { vi.advanceTimersByTime(HOLD_MS) })
    expect(onSos).toHaveBeenCalledTimes(1)
  })

  it("offers a direct emergency call", () => {
    render(<SosButton onSos={() => {}} />)
    expect(screen.getByText("Call 911").getAttribute("href")).toBe("tel:911")
  })
})

import GrainfallCore
import MetalKit
import SwiftUI

/// MTKView that forwards touches as grid coordinates.
final class GridMTKView: MTKView {
    var insets: (top: Double, bottom: Double) = (0, 0)
    var onTouch: ((TouchPhase, Point) -> Void)?

    enum TouchPhase { case began, moved, ended }

    private func cell(for touch: UITouch) -> Point {
        let p = touch.location(in: self)
        return Letterbox(viewWidth: bounds.width, viewHeight: bounds.height,
                         topInset: insets.top, bottomInset: insets.bottom).cell(atX: p.x, y: p.y)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let t = touches.first { onTouch?(.began, cell(for: t)) }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        // Coalesced touches keep fast strokes continuous at 120 Hz sampling.
        for c in event?.coalescedTouches(for: t) ?? [t] { onTouch?(.moved, cell(for: c)) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let t = touches.first { onTouch?(.ended, cell(for: t)) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let t = touches.first { onTouch?(.ended, cell(for: t)) }
    }
}

/// SwiftUI wrapper. The renderer pulls frames from the controller; touches go back to it.
struct GridView: UIViewRepresentable {
    let controller: GameController
    var insets: (top: Double, bottom: Double) = (0, 0)
    var interactive = true

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator { var renderer: PixelRenderer? }

    func makeUIView(context: Context) -> GridMTKView {
        let view = GridMTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = true
        view.isMultipleTouchEnabled = false
        view.isUserInteractionEnabled = interactive
        view.isAccessibilityElement = true
        view.accessibilityLabel = String(localized: "Game board")
        view.accessibilityHint = String(localized: "Drag to dig through dirt. Tap a striped gate to open it.")
        let renderer = PixelRenderer(view: view)
        context.coordinator.renderer = renderer
        configure(view, renderer: renderer)
        return view
    }

    func updateUIView(_ view: GridMTKView, context: Context) {
        configure(view, renderer: context.coordinator.renderer)
    }

    @MainActor private func configure(_ view: GridMTKView, renderer: PixelRenderer?) {
        view.insets = insets
        renderer?.insets = insets
        renderer?.frameSource = { [weak controller] now in controller?.frame(now: now) ?? [] }
        view.onTouch = { [weak controller] phase, p in
            MainActor.assumeIsolated { controller?.touch(phase, at: p) }
        }
    }
}

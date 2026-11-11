import GrainfallCore

/// The seam to the studio engine (spec §1.1): anything that can show a w×h RGBA8 frame,
/// letterboxed with nearest-neighbour sampling. `PixelRenderer` is the built-in Metal implementation.
@MainActor
protocol PixelSurface: AnyObject {
    /// Called once per display frame; returns the frame to show.
    var frameSource: (@MainActor (_ now: Double) -> [UInt32])? { get set }
    /// Insets (in points) reserved for HUD chrome above and below the board.
    var insets: (top: Double, bottom: Double) { get set }
}

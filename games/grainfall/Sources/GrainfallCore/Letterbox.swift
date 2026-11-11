/// Aspect-fit placement of the grid inside a view, and the inverse mapping for touches
/// (spec §1.1). Units are whatever the caller uses (points for touches, pixels for the viewport).
public struct Letterbox: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    /// Fits a `gridWidth × gridHeight` grid into `viewWidth × viewHeight`, centred, after
    /// reserving `topInset`/`bottomInset` (for the HUD).
    public init(viewWidth: Double, viewHeight: Double, gridWidth: Int = Grid.width, gridHeight: Int = Grid.height,
                topInset: Double = 0, bottomInset: Double = 0) {
        let availH = max(1, viewHeight - topInset - bottomInset)
        let scale = min(viewWidth / Double(gridWidth), availH / Double(gridHeight))
        width = Double(gridWidth) * scale
        height = Double(gridHeight) * scale
        x = (viewWidth - width) / 2
        y = topInset + (availH - height) / 2
    }

    public var scale: Double { width / Double(Grid.width) }

    /// Grid cell under a view-space point (may be outside the grid; callers clamp or ignore).
    public func cell(atX px: Double, y py: Double, gridWidth: Int = Grid.width, gridHeight: Int = Grid.height) -> Point {
        let gx = (px - x) / width * Double(gridWidth)
        let gy = (py - y) / height * Double(gridHeight)
        return Point(Int(gx.rounded(.down)), Int(gy.rounded(.down)))
    }

    /// The same letterbox expressed in another unit (e.g. points → drawable pixels).
    public func scaled(by s: Double) -> Letterbox {
        var l = self
        l.x *= s; l.y *= s; l.width *= s; l.height *= s
        return l
    }
}

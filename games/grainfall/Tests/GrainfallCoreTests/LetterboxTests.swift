@testable import GrainfallCore
import XCTest

final class LetterboxTests: XCTestCase {
    func testFitsWidthOnTallPhone() {
        // iPhone 15: 393 × 852 pt, HUD reserves 60 pt top and 40 pt bottom.
        let l = Letterbox(viewWidth: 393, viewHeight: 852, topInset: 60, bottomInset: 40)
        XCTAssertEqual(l.width, 393, accuracy: 0.001)
        XCTAssertEqual(l.height, 393.0 / 128.0 * 240.0, accuracy: 0.001)
        XCTAssertEqual(l.y, 60 + (752 - l.height) / 2, accuracy: 0.001)
    }

    func testFitsHeightOnWideView() {
        let l = Letterbox(viewWidth: 1000, viewHeight: 480)
        XCTAssertEqual(l.height, 480)
        XCTAssertEqual(l.width, 256)
        XCTAssertEqual(l.x, 372)
    }

    func testTouchMappingRoundTrips() {
        let l = Letterbox(viewWidth: 393, viewHeight: 852, topInset: 60, bottomInset: 40)
        let s = l.scale
        for (gx, gy) in [(0, 0), (64, 120), (127, 239)] {
            let p = l.cell(atX: l.x + (Double(gx) + 0.5) * s, y: l.y + (Double(gy) + 0.5) * s)
            XCTAssertEqual(p, Point(gx, gy))
        }
        XCTAssertEqual(l.cell(atX: l.x - 1, y: l.y).x, -1, "outside the grid stays outside")
        XCTAssertEqual(l.scaled(by: 3).width, l.width * 3, accuracy: 0.001)
    }
}

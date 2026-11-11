@testable import GrainfallCore
import Foundation
import XCTest

/// Content checks for every shipped level (spec §3, R-LVL-1…4).
final class LevelContentTests: XCTestCase {
    var catalog: LevelCatalog!

    override func setUpWithError() throws {
        catalog = try LevelCatalog.bundled()
    }

    func testCatalogShape() {
        XCTAssertEqual(catalog.chapters.count, 3)
        XCTAssertEqual(catalog.orderedLevelIDs.count, 12)
        XCTAssertTrue(catalog.chapters[0].free)
        XCTAssertFalse(catalog.chapters.last!.free, "the last chapter is behind the Full Game unlock")
        XCTAssertEqual(catalog.level(after: "1-4"), "2-1")
        XCTAssertNil(catalog.level(after: "3-4"))
    }

    func testEveryLevelNeedsThePlayer() {
        for id in catalog.orderedLevelIDs {
            let r = Replay.run(catalog.levels[id]!, actions: [], stopWhenStuck: true)
            XCTAssertNotEqual(r.status, .won, "\(id) wins without any input")
        }
    }

    func testEveryLevelIsSolvableWithThreeStars() {
        for id in catalog.orderedLevelIDs {
            let level = catalog.levels[id]!
            XCTAssertFalse(level.solution.isEmpty, "\(id) has no reference solution")
            let r = Replay.solve(level)
            XCTAssertEqual(r.status, .won, "\(id) reference solution doesn't win")
            XCTAssertEqual(r.stars, 3, "\(id) reference solution dug \(r.dug), par3 is \(level.par3)")
            XCTAssertLessThanOrEqual(level.par2, level.digBudget, "\(id) 2-star par is unreachable")
        }
    }

    func testTrapsDoNotWin() {
        for id in catalog.orderedLevelIDs {
            for (n, trap) in catalog.levels[id]!.traps.enumerated() {
                XCTAssertNotEqual(Replay.run(catalog.levels[id]!, actions: trap, stopWhenStuck: true).status, .won, "\(id) trap \(n) wins")
            }
        }
    }
}

final class LevelLoaderTests: XCTestCase {
    func decode(_ json: String) throws -> LevelDefinition { try LevelLoader.decode(Data(json.utf8)) }

    let base = """
    {"id": "x", "name": "X", "seed": 1, "digBudget": 100, "par": [10, 20],
     "shapes": [SHAPES], "spouts": [{"x": 64, "y": 4, "m": "sand", "rate": 1, "total": 100}],
     "cups": [{"x": 40, "y": 200, "w": 20, "h": 20, "accepts": "sand", "required": REQ}],
     "solution": [{"t": 0, "dig": [1, 2, 3, 4, 5, 6]}, {"t": 5, "gate": [7, 8]}]}
    """

    func level(shapes: String = "", required: Int = 50) -> String {
        base.replacingOccurrences(of: "SHAPES", with: shapes).replacingOccurrences(of: "REQ", with: "\(required)")
    }

    func testDecodesShapesAndPolylineSolutions() throws {
        let l = try decode(level(shapes: #"{"op": "line", "m": "wall", "x0": 0, "y0": 0, "x1": 10, "y1": 10}"#))
        XCTAssertEqual(l.shapes, [.line(.wall, x0: 0, y0: 0, x1: 10, y1: 10, t: 1)])
        XCTAssertEqual(l.spouts[0].delay, 60, "PRD: one second to read the board")
        XCTAssertEqual(l.solution, [
            TimedAction(tick: 0, action: .dig(from: Point(1, 2), to: Point(3, 4))),
            TimedAction(tick: 0, action: .dig(from: Point(3, 4), to: Point(5, 6))),
            TimedAction(tick: 5, action: .openGate(at: Point(7, 8))),
        ])
    }

    func testRejectsBadLevels() {
        XCTAssertThrowsError(try decode(level(shapes: #"{"op": "blob", "m": "wall"}"#)))
        XCTAssertThrowsError(try decode(level(shapes: #"{"op": "rect", "m": "unobtainium", "x": 0, "y": 0, "w": 1, "h": 1}"#)))
        XCTAssertThrowsError(try decode(level(shapes: #"{"op": "rect", "m": "wall", "x": 120, "y": 0, "w": 20, "h": 1}"#)))
        XCTAssertThrowsError(try decode(level(required: 101)), "more than the spouts provide")
        XCTAssertThrowsError(try decode(level(shapes: """
            {"op": "gate", "id": 1, "x": 0, "y": 0, "w": 2, "h": 2}, {"op": "gate", "id": 1, "x": 5, "y": 5, "w": 2, "h": 2}
            """)), "duplicate gate id")
        XCTAssertThrowsError(try decode(level().replacingOccurrences(of: "[10, 20]", with: "[30, 20]")))
        XCTAssertThrowsError(try decode(level(shapes: #"{"op": "rect", "m": "sand", "x": 40, "y": 205, "w": 2, "h": 2}"#)),
                             "cup pre-filled with its own material")
    }

    func testPrefilledMaterialCountsAsAvailable() throws {
        XCTAssertNoThrow(try decode(level(shapes: #"{"op": "rect", "m": "sand", "x": 0, "y": 50, "w": 10, "h": 10}"#,
                                          required: 150)))
    }
}

final class ProgressTests: XCTestCase {
    var catalog: LevelCatalog!

    override func setUpWithError() throws { catalog = try LevelCatalog.bundled() }

    func complete(_ ids: [String], in p: inout PlayerProgress) { ids.forEach { p.record(levelID: $0, stars: 1) } }

    func testUnlocksInOrder() {
        var p = PlayerProgress()
        XCTAssertTrue(p.isUnlocked("1-1", in: catalog, fullGame: false))
        XCTAssertFalse(p.isUnlocked("1-2", in: catalog, fullGame: false))
        p.record(levelID: "1-1", stars: 2)
        XCTAssertTrue(p.isUnlocked("1-2", in: catalog, fullGame: false))
        XCTAssertFalse(p.isUnlocked("2-1", in: catalog, fullGame: false), "chapter 1 not finished")
        complete(["1-2", "1-3", "1-4"], in: &p)
        XCTAssertTrue(p.isUnlocked("2-1", in: catalog, fullGame: false))
        XCTAssertEqual(p.nextLevel(in: catalog, fullGame: false), "2-1")
    }

    func testPaidChapterNeedsFullGame() {
        var p = PlayerProgress()
        complete(catalog.chapters[0].levels + catalog.chapters[1].levels, in: &p)
        XCTAssertFalse(p.isUnlocked("3-1", in: catalog, fullGame: false))
        XCTAssertTrue(p.isUnlocked("3-1", in: catalog, fullGame: true))
        XCTAssertFalse(p.isUnlocked("3-2", in: catalog, fullGame: true))
    }

    func testKeepsBestStars() {
        var p = PlayerProgress()
        XCTAssertTrue(p.record(levelID: "1-1", stars: 2))
        XCTAssertFalse(p.record(levelID: "1-1", stars: 1))
        XCTAssertTrue(p.record(levelID: "1-1", stars: 3))
        XCTAssertEqual(p.stars("1-1"), 3)
        XCTAssertEqual(p.totalStars(in: catalog), 3)
    }

    func testStoreRoundTripAndCorruptRecovery() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ProgressStore(url: dir.appendingPathComponent("progress.json"))
        XCTAssertEqual(store.load(), PlayerProgress(), "missing file → fresh progress")

        var p = PlayerProgress()
        p.record(levelID: "1-1", stars: 3)
        p.settings.haptics = false
        p.seenHints.insert("1-1")
        try store.save(p)
        XCTAssertEqual(store.load(), p)

        try Data("{not json".utf8).write(to: store.url)
        XCTAssertEqual(store.load(), PlayerProgress(), "corrupt file → fresh progress, no crash")
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.url.appendingPathExtension("corrupt").path))
    }
}

final class SaveCompatibilityTests: XCTestCase {
    func testDecodesVersionOneSaveWithoutNewFields() throws {
        let old = #"{"schemaVersion":1,"bestStars":{"1-1":3},"settings":{"haptics":false},"seenHints":["1-1"]}"#
        let p = try JSONDecoder().decode(PlayerProgress.self, from: Data(old.utf8))
        XCTAssertEqual(p.stars("1-1"), 3)
        XCTAssertFalse(p.settings.haptics)
        XCTAssertTrue(p.settings.sound)
        XCTAssertTrue(p.settings.music)
        XCTAssertEqual(p.wins, 0)
    }

    func testEmissiveRenderMarksLavaOnly() {
        let w = World(level: LevelDefinition(id: "e", name: "e", shapes: [.rect(.lava, x: 0, y: 239, w: 1, h: 1),
                                                                           .rect(.sand, x: 5, y: 239, w: 1, h: 1)],
                                             spouts: [], cups: [CupDef(x: 60, y: 0, w: 4, h: 4, accepts: .sand, required: 1)]))
        var px: [UInt32] = []
        w.render(into: &px, emissive: true)
        XCTAssertGreaterThan(px[239 * Grid.width] >> 24, 100)
        XCTAssertEqual(px[239 * Grid.width + 5] >> 24, 0)
        XCTAssertEqual(px[60] >> 24, 0, "cup tint doesn't glow")
    }
}

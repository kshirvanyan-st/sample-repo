@testable import GrainfallCore
import XCTest

/// Small sandbox level: no spouts, a far-away cup that nothing reaches.
func sandbox(seed: UInt64 = 1, shapes: [Shape] = [], spouts: [SpoutDef] = [], cups: [CupDef]? = nil,
             digBudget: Int = 10_000) -> LevelDefinition {
    LevelDefinition(id: "t", name: "test", seed: seed, digBudget: digBudget, par: [100, 200], shapes: shapes,
                    spouts: spouts,
                    cups: cups ?? [CupDef(x: 0, y: 0, w: 2, h: 2, accepts: .sand, required: 4)])
}

final class MaterialTests: XCTestCase {
    func testSandFallsAndPiles() {
        var w = World(level: sandbox(shapes: [.rect(.sand, x: 60, y: 100, w: 1, h: 1)]))
        w.step(200)
        XCTAssertEqual(w.grid.at(60, Grid.height - 1), .sand, "a single grain falls to the floor")

        var pile = World(level: sandbox(shapes: [.rect(.sand, x: 60, y: 20, w: 9, h: 40)]))
        pile.step(600)
        XCTAssertEqual(pile.grid.count(.sand), 360, "sand is conserved")
        // A pile spreads wider than the column it fell from, and its top is lower than the column was tall.
        let bottom = Grid.height - 1
        let width = (0..<Grid.width).filter { pile.grid.at($0, bottom) == .sand }.count
        XCTAssertGreaterThan(width, 20)
        XCTAssertEqual(pile.grid.at(64, bottom - 39), .empty)
    }

    func testWaterLevelsOut() {
        var w = World(level: sandbox(shapes: [.rect(.water, x: 0, y: 100, w: 16, h: 16)]))
        w.step(600)
        XCTAssertEqual(w.grid.count(.water), 256)
        // 256 cells over a 128-wide floor → the bottom two rows are (almost) all water.
        let bottomRow = (0..<Grid.width).filter { w.grid.at($0, Grid.height - 1) == .water }.count
        XCTAssertGreaterThan(bottomRow, 120)
    }

    func testSandSinksThroughWater() {
        var w = World(level: sandbox(shapes: [
            .rect(.water, x: 60, y: 227, w: 8, h: 10),
            .cup(.wall, x: 57, y: 200, w: 14, h: 40, t: 3),
            .rect(.sand, x: 60, y: 190, w: 8, h: 2),
        ]))
        w.step(300)
        XCTAssertEqual(w.grid.at(64, Grid.height - 4), .sand, "sand ends up at the bottom of the tank")
        XCTAssertEqual(w.grid.count(.sand), 16)
        XCTAssertEqual(w.grid.count(.water), 80)
    }

    func testLavaAndWaterMakeStoneAndSteam() {
        var w = World(level: sandbox(shapes: [.rect(.water, x: 50, y: 239, w: 20, h: 1),
                                              .rect(.lava, x: 60, y: 200, w: 1, h: 1)]))
        w.step(120)
        XCTAssertGreaterThanOrEqual(w.grid.count(.stone), 1)
        XCTAssertEqual(w.grid.count(.lava), 0)
    }

    func testFireBurnsPlantAway() {
        var w = World(level: sandbox(shapes: [.rect(.plant, x: 40, y: 150, w: 40, h: 3),
                                              .rect(.lava, x: 40, y: 149, w: 1, h: 1)]))
        w.step(1500)
        XCTAssertEqual(w.grid.count(.plant), 0, "fire spreads through the whole plant strip")
        XCTAssertEqual(w.grid.count(.fire), 0, "and burns out")
    }

    func testSteamRisesAndFades() throws {
        var w = World(level: sandbox())
        w.grid.set(64, 200, .steam, life: 50)
        w.step(10)
        let row = (0..<Grid.height).first { y in (0..<Grid.width).contains { w.grid.at($0, y) == .steam } }
        XCTAssertLessThan(try XCTUnwrap(row), 195, "steam rises")
        w.step(100)
        XCTAssertEqual(w.grid.count(.steam), 0)
    }

    func testOutOfBoundsIsWall() {
        let g = Grid()
        XCTAssertEqual(g.at(-1, 0), .wall)
        XCTAssertEqual(g.at(0, Grid.height), .wall)
    }
}

final class DeterminismTests: XCTestCase {
    func testSameSeedAndActionsGiveIdenticalGrids() throws {
        let level = try XCTUnwrap(LevelCatalog.bundled().levels["2-3"])
        let a = Replay.solve(level, maxTicks: 400).world.grid.hashValueForTesting
        let b = Replay.solve(level, maxTicks: 400).world.grid.hashValueForTesting
        XCTAssertEqual(a, b)
    }

    func testDifferentSeedDiverges() throws {
        var level = try XCTUnwrap(LevelCatalog.bundled().levels["1-1"])
        let a = Replay.solve(level, maxTicks: 300).world.grid.hashValueForTesting
        level.seed += 1
        let b = Replay.solve(level, maxTicks: 300).world.grid.hashValueForTesting
        XCTAssertNotEqual(a, b)
    }

    func testRNGIsStable() {
        var r = RNG(seed: 42)
        // Pinned values: changing the generator would silently change every level's behaviour.
        XCTAssertEqual([r.next(), r.next()], [2_949_826_092_126_892_291, 5_139_283_748_462_763_858])
    }
}

final class ActionTests: XCTestCase {
    func testDigClearsOnlyDirtAndCountsCost() {
        var w = World(level: sandbox(shapes: [.rect(.dirt, x: 0, y: 100, w: 128, h: 20),
                                              .rect(.wall, x: 64, y: 100, w: 2, h: 20)]))
        let cleared = w.apply(.dig(from: Point(64, 110), to: Point(64, 110)))
        XCTAssertGreaterThan(cleared, 30)
        XCTAssertEqual(w.dug, cleared)
        XCTAssertEqual(w.digBudget, 10_000 - cleared)
        XCTAssertEqual(w.grid.at(64, 110), .wall, "walls survive")
        XCTAssertEqual(w.grid.at(62, 110), .empty)
        XCTAssertEqual(w.grid.at(64 - World.digRadius - 1, 110), .dirt, "radius respected")
    }

    func testDigStopsWhenBudgetRunsOut() {
        var w = World(level: sandbox(shapes: [.rect(.dirt, x: 0, y: 100, w: 128, h: 20)], digBudget: 10))
        w.apply(.dig(from: Point(10, 110), to: Point(100, 110)))
        XCTAssertEqual(w.dug, 10)
        XCTAssertEqual(w.digBudget, 0)
        XCTAssertEqual(w.apply(.dig(from: Point(10, 110), to: Point(100, 110))), 0)
    }

    func testGateOpensWholeGateByID() {
        var w = World(level: sandbox(shapes: [.gate(id: 1, x: 10, y: 50, w: 30, h: 3),
                                              .gate(id: 2, x: 80, y: 50, w: 10, h: 3)]))
        XCTAssertEqual(w.gateID(near: Point(12, 55)), 1)
        XCTAssertNil(w.gateID(near: Point(60, 120)))
        XCTAssertEqual(w.apply(.openGate(at: Point(39, 51))), 90)
        XCTAssertEqual(w.grid.count(.gate), 30, "only gate 2 remains")
        XCTAssertEqual(w.openedGates, [1])
    }
}

final class CupTests: XCTestCase {
    func testCupCountsAcceptedMaterialAndWins() {
        var w = World(level: sandbox(shapes: [.rect(.sand, x: 10, y: 200, w: 10, h: 2)],
                                     cups: [CupDef(x: 0, y: 230, w: 30, h: 10, accepts: .sand, required: 20)]))
        w.step(100)
        XCTAssertEqual(w.cups[0].collected, 20)
        XCTAssertEqual(w.status, .won)
        XCTAssertEqual(w.stars, 3)
    }

    func testForbiddenMaterialFailsTheLevel() {
        var w = World(level: sandbox(shapes: [.rect(.lava, x: 10, y: 225, w: 2, h: 1)],
                                     cups: [CupDef(x: 0, y: 230, w: 30, h: 10, accepts: .water, required: 20,
                                                   forbids: [.lava])]))
        w.step(200)
        XCTAssertEqual(w.status, .failed(.contaminated(cup: 0, by: .lava)))
        let tick = w.tick
        w.step(10)
        XCTAssertEqual(w.tick, tick, "terminal worlds stop ticking")
    }

    func testStuckFlagAfterIdleTicks() {
        var w = World(level: sandbox(spouts: [SpoutDef(x: 64, y: 5, m: .sand, rate: 1, total: 5, width: 1, delay: 0)]))
        w.step(World.stuckAfterTicks - 10)
        XCTAssertFalse(w.isStuck)
        w.step(30)
        XCTAssertTrue(w.isStuck)
        XCTAssertEqual(w.status, .playing, "stuck is a hint, not a loss")
        w.apply(.dig(from: Point(0, 0), to: Point(0, 0)))
        XCTAssertTrue(w.isStuck, "a dig that clears nothing doesn't count as progress")
    }

    func testSpoutEmitsExactlyTotal() {
        var w = World(level: sandbox(spouts: [SpoutDef(x: 64, y: 5, m: .water, rate: 3, total: 50, width: 6, delay: 10)]))
        w.step(10)
        XCTAssertEqual(w.grid.count(.water), 0, "delay respected")
        w.step(200)
        XCTAssertEqual(w.grid.count(.water), 50)
        XCTAssertTrue(w.spouts[0].exhausted)
    }
}

final class RenderTests: XCTestCase {
    func testRenderFillsBufferWithPaletteColours() {
        let w = World(level: sandbox(shapes: [.rect(.wall, x: 0, y: 0, w: 1, h: 1)]))
        var px: [UInt32] = []
        w.render(into: &px)
        XCTAssertEqual(px.count, Grid.width * Grid.height)
        XCTAssertTrue(Palette.shades(.wall).map(\.packed).contains(px[0]))
        XCTAssertEqual(px[Grid.width * 120 + 64], Palette.background.packed)
    }

    func testPackedIsRGBAByteOrder() {
        let c = RGBA(1, 2, 3, 4).packed
        withUnsafeBytes(of: c.littleEndian) { XCTAssertEqual(Array($0), [1, 2, 3, 4]) }
    }
}

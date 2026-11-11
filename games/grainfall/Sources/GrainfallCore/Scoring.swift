/// Star rating from how little the player dug (spec §2.10, R-SCORE-1).
public enum Scoring {
    public static func stars(dug: Int, level: LevelDefinition) -> Int {
        if dug <= level.par3 { return 3 }
        if dug <= level.par2 { return 2 }
        return 1
    }
}

/// Runs a level headlessly with scripted actions (used by tests, the CLI and replays).
public enum Replay {
    public struct Result: Sendable {
        public var status: GameStatus
        public var ticks: Int
        public var dug: Int
        public var stars: Int
        public var world: World
    }

    /// `stopWhenStuck` ends the run early once every scripted action has been applied and the
    /// world reports `isStuck` — used by content checks that only need to know the level isn't won.
    public static func run(_ level: LevelDefinition, actions: [TimedAction], maxTicks: Int = 3600,
                           stopWhenStuck: Bool = false) -> Result {
        var world = World(level: level)
        let sorted = actions.sorted { $0.tick < $1.tick }
        var next = 0
        while world.tick < maxTicks, world.status == .playing {
            while next < sorted.count, sorted[next].tick <= world.tick {
                world.apply(sorted[next].action)
                next += 1
            }
            if stopWhenStuck, next == sorted.count, world.isStuck { break }
            world.step()
        }
        return Result(status: world.status, ticks: world.tick, dug: world.dug, stars: world.stars, world: world)
    }

    public static func solve(_ level: LevelDefinition, maxTicks: Int = 3600) -> Result {
        run(level, actions: level.solution, maxTicks: maxTicks)
    }
}

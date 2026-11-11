import Foundation

/// The player's saved state (spec §6). Purchase entitlement is deliberately *not* stored here:
/// StoreKit is the source of truth.
public struct PlayerProgress: Codable, Equatable, Sendable {
    public static let currentSchema = 1

    public struct Settings: Codable, Equatable, Sendable {
        public var haptics = true
        public var sound = true
        public var music = true
        public init() {}

        // Every field is optional on decode so saves from older versions keep loading.
        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            haptics = try c.decodeIfPresent(Bool.self, forKey: .haptics) ?? true
            sound = try c.decodeIfPresent(Bool.self, forKey: .sound) ?? true
            music = try c.decodeIfPresent(Bool.self, forKey: .music) ?? true
        }
    }

    public var schemaVersion = PlayerProgress.currentSchema
    public var bestStars: [String: Int] = [:]
    public var settings = Settings()
    /// Level hints already shown once.
    public var seenHints: Set<String> = []
    /// Levels completed in total (including replays) — drives the review prompt and stats.
    public var wins = 0
    /// Whether the store review prompt has been requested (we ask once, at a happy moment).
    public var askedForReview = false

    public init() {}

    enum CodingKeys: String, CodingKey { case schemaVersion, bestStars, settings, seenHints, wins, askedForReview }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? PlayerProgress.currentSchema
        bestStars = try c.decodeIfPresent([String: Int].self, forKey: .bestStars) ?? [:]
        settings = try c.decodeIfPresent(Settings.self, forKey: .settings) ?? Settings()
        seenHints = try c.decodeIfPresent(Set<String>.self, forKey: .seenHints) ?? []
        wins = try c.decodeIfPresent(Int.self, forKey: .wins) ?? 0
        askedForReview = try c.decodeIfPresent(Bool.self, forKey: .askedForReview) ?? false
    }

    /// True when every level of the chapter has 3 stars.
    public func isPerfect(_ chapter: Chapter) -> Bool { chapter.levels.allSatisfy { stars($0) == 3 } }

    public func isComplete(_ chapter: Chapter) -> Bool { chapter.levels.allSatisfy(isCompleted) }

    public func stars(_ levelID: String) -> Int { bestStars[levelID] ?? 0 }

    public func isCompleted(_ levelID: String) -> Bool { stars(levelID) > 0 }

    /// Keeps the best result. Returns true if it improved.
    @discardableResult
    public mutating func record(levelID: String, stars: Int) -> Bool {
        guard stars > self.stars(levelID) else { return false }
        bestStars[levelID] = min(3, stars)
        return true
    }

    public func totalStars(in catalog: LevelCatalog) -> Int {
        catalog.orderedLevelIDs.reduce(0) { $0 + stars($1) }
    }

    public func isChapterUnlocked(_ chapter: Chapter, in catalog: LevelCatalog, fullGame: Bool) -> Bool {
        guard let idx = catalog.chapters.firstIndex(of: chapter) else { return false }
        if !chapter.free && !fullGame { return false }
        if idx == 0 { return true }
        return catalog.chapters[idx - 1].levels.allSatisfy(isCompleted)
    }

    /// Unlock rules from spec §6.
    public func isUnlocked(_ levelID: String, in catalog: LevelCatalog, fullGame: Bool) -> Bool {
        guard let chapter = catalog.chapter(of: levelID),
              isChapterUnlocked(chapter, in: catalog, fullGame: fullGame),
              let pos = chapter.levels.firstIndex(of: levelID) else { return false }
        return pos == 0 || isCompleted(chapter.levels[pos - 1])
    }

    /// First unlocked, unfinished level — where "Play" resumes.
    public func nextLevel(in catalog: LevelCatalog, fullGame: Bool) -> String? {
        let ids = catalog.orderedLevelIDs
        return ids.first { !isCompleted($0) && isUnlocked($0, in: catalog, fullGame: fullGame) }
            ?? ids.last { isUnlocked($0, in: catalog, fullGame: fullGame) }
    }
}

/// Atomic JSON persistence with corrupt-file recovery (R-SAVE-1).
public final class ProgressStore: @unchecked Sendable {
    public let url: URL
    private let lock = NSLock()

    public init(url: URL) { self.url = url }

    public static func applicationSupport(fileName: String = "progress.json") throws -> ProgressStore {
        let dir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                              appropriateFor: nil, create: true)
        return ProgressStore(url: dir.appendingPathComponent(fileName))
    }

    public func load() -> PlayerProgress {
        lock.lock(); defer { lock.unlock() }
        guard FileManager.default.fileExists(atPath: url.path) else { return PlayerProgress() }
        do {
            let p = try JSONDecoder().decode(PlayerProgress.self, from: Data(contentsOf: url))
            return p.schemaVersion <= PlayerProgress.currentSchema ? p : PlayerProgress()
        } catch {
            let aside = url.appendingPathExtension("corrupt")
            try? FileManager.default.removeItem(at: aside)
            try? FileManager.default.moveItem(at: url, to: aside)
            return PlayerProgress()
        }
    }

    public func save(_ progress: PlayerProgress) throws {
        lock.lock(); defer { lock.unlock() }
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try enc.encode(progress).write(to: url, options: .atomic)
    }
}

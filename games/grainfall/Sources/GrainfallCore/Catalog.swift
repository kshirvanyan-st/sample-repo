import Foundation

public struct Chapter: Decodable, Equatable, Sendable {
    public var id: Int
    public var name: String
    /// Playable without the Full Game purchase (PRD §5.6).
    public var free: Bool
    public var levels: [String]
}

/// All shipped chapters and levels, loaded from the package's `levels/` resource folder.
public struct LevelCatalog: Sendable {
    public let chapters: [Chapter]
    public let levels: [String: LevelDefinition]

    public init(chapters: [Chapter], levels: [String: LevelDefinition]) {
        self.chapters = chapters
        self.levels = levels
    }

    public static func bundled() throws -> LevelCatalog {
        guard let dir = Bundle.module.url(forResource: "levels", withExtension: nil) else {
            throw LevelError.invalid("catalog", "levels resource folder missing")
        }
        return try load(from: dir)
    }

    public static func load(from dir: URL) throws -> LevelCatalog {
        let chapters = try JSONDecoder().decode([Chapter].self,
                                                from: Data(contentsOf: dir.appendingPathComponent("chapters.json")))
        var levels: [String: LevelDefinition] = [:]
        for id in chapters.flatMap(\.levels) {
            let url = dir.appendingPathComponent("\(id).json")
            do {
                levels[id] = try LevelLoader.decode(Data(contentsOf: url))
            } catch let e as LevelError {
                throw e
            } catch {
                throw LevelError.invalid(id, "\(error)")
            }
            if levels[id]?.id != id { throw LevelError.invalid(id, "file id does not match chapters.json") }
        }
        if Set(chapters.flatMap(\.levels)).count != chapters.flatMap(\.levels).count {
            throw LevelError.invalid("catalog", "a level appears in more than one chapter")
        }
        return LevelCatalog(chapters: chapters, levels: levels)
    }

    /// Levels in play order.
    public var orderedLevelIDs: [String] { chapters.flatMap(\.levels) }

    public func chapter(of levelID: String) -> Chapter? { chapters.first { $0.levels.contains(levelID) } }

    public func level(after id: String) -> String? {
        let all = orderedLevelIDs
        guard let i = all.firstIndex(of: id), i + 1 < all.count else { return nil }
        return all[i + 1]
    }
}

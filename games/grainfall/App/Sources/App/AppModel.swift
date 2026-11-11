import Combine
import GrainfallCore
import SwiftUI

enum Screen: Equatable {
    case title
    case levels
    case game(String)
}

/// App-wide state: navigation, saved progress and purchase entitlement.
@MainActor
final class AppModel: ObservableObject {
    @Published var screen: Screen = .title
    @Published private(set) var progress: PlayerProgress
    @Published var showPaywall = false
    @Published var showSettings = false

    let catalog: LevelCatalog
    let store: StoreService
    let haptics = Haptics()
    let audio = AudioEngine()
    let gameCenter = GameCenter()
    /// Set after a win that should trigger the one-time App Store review prompt.
    @Published var wantsReview = false
    /// Chapter just completed for the first time (shown as a celebration on the results card).
    @Published var justCompletedChapter: Chapter?
    private let progressStore: ProgressStore?
    private var cancellables: Set<AnyCancellable> = []

    init(catalog: LevelCatalog? = nil, progressStore: ProgressStore? = try? .applicationSupport(),
         store: StoreService? = nil) {
        // The catalog ships inside the app; failing to load it is a build error caught by CI.
        self.catalog = catalog ?? (try! LevelCatalog.bundled())
        self.progressStore = progressStore
        self.store = store ?? StoreService()
        self.progress = progressStore?.load() ?? PlayerProgress()
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-GFStartLevel"), i + 1 < args.count { launchLevel = args[i + 1] } else { launchLevel = nil }
        autoplay = args.contains("-GFAutoplay")
        unlockAll = args.contains("-GFUnlockAll")
        haptics.isEnabled = progress.settings.haptics
        audio.soundEnabled = progress.settings.sound
        audio.musicEnabled = progress.settings.music
        // Purchases change what's unlocked: re-render anything observing the model.
        self.store.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    /// Launch arguments for automated screenshots and CI smoke tests (never set in normal use):
    /// `-GFStartLevel <id>` opens a level, `-GFAutoplay` replays its solution, `-GFUnlockAll`
    /// ignores locks.
    let launchLevel: String?
    let autoplay: Bool
    private let unlockAll: Bool

    var hasFullGame: Bool { store.hasFullGame || unlockAll }

    func level(_ id: String) -> LevelDefinition? { catalog.levels[id] }

    func isUnlocked(_ id: String) -> Bool {
        unlockAll || progress.isUnlocked(id, in: catalog, fullGame: hasFullGame)
    }

    func isChapterUnlocked(_ c: Chapter) -> Bool { progress.isChapterUnlocked(c, in: catalog, fullGame: hasFullGame) }

    /// Locked only because it's a paid chapter (as opposed to not reached yet).
    func needsPurchase(_ c: Chapter) -> Bool { !c.free && !hasFullGame }

    var continueLevel: String? { progress.nextLevel(in: catalog, fullGame: hasFullGame) }

    func play(_ id: String) {
        guard isUnlocked(id) else {
            if let c = catalog.chapter(of: id), needsPurchase(c) { showPaywall = true }
            return
        }
        screen = .game(id)
    }

    /// Next level after `id`, or the paywall if the next chapter is paid and locked.
    func playNext(after id: String) {
        guard let next = catalog.level(after: id) else { screen = .levels; return }
        if isUnlocked(next) {
            screen = .game(next)
        } else if let c = catalog.chapter(of: next), needsPurchase(c) {
            screen = .levels
            showPaywall = true
        } else {
            screen = .levels
        }
    }

    /// Call once on launch.
    func start() {
        audio.start()
        if let launchLevel, catalog.levels[launchLevel] != nil {
            screen = .game(launchLevel)
        } else {
            gameCenter.authenticate()
        }
    }

    /// Records a win. Returns true if it was a new best.
    @discardableResult
    func record(levelID: String, stars: Int) -> Bool {
        let chapter = catalog.chapter(of: levelID)
        let wasComplete = chapter.map(progress.isComplete) ?? true
        progress.wins += 1
        let improved = progress.record(levelID: levelID, stars: stars)
        if let chapter, !wasComplete, progress.isComplete(chapter) { justCompletedChapter = chapter }
        // Ask for a rating once, at a happy moment: a 3-star win after the player is clearly engaged.
        if stars == 3, progress.wins >= 8, !progress.askedForReview {
            progress.askedForReview = true
            wantsReview = true
        }
        save()
        if improved { gameCenter.report(progress: progress, catalog: catalog) }
        return improved
    }

    func markHintSeen(_ id: String) {
        guard progress.seenHints.insert(id).inserted else { return }
        save()
    }

    func setHaptics(_ on: Bool) {
        progress.settings.haptics = on
        haptics.isEnabled = on
        save()
    }

    func setSound(_ on: Bool) {
        progress.settings.sound = on
        audio.soundEnabled = on
        save()
    }

    func setMusic(_ on: Bool) {
        progress.settings.music = on
        audio.musicEnabled = on
        save()
    }

    /// Erases stars and settings (Settings → Reset Progress). Purchases are unaffected.
    func resetProgress() {
        progress = PlayerProgress()
        haptics.isEnabled = true
        audio.soundEnabled = true
        audio.musicEnabled = true
        save()
    }

    private func save() {
        do { try progressStore?.save(progress) } catch { assertionFailure("save failed: \(error)") }
    }
}

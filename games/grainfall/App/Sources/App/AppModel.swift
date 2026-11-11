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
    private let progressStore: ProgressStore?
    private var cancellables: Set<AnyCancellable> = []

    init(catalog: LevelCatalog? = nil, progressStore: ProgressStore? = try? .applicationSupport(),
         store: StoreService = StoreService()) {
        // The catalog ships inside the app; failing to load it is a build error caught by CI.
        self.catalog = catalog ?? (try! LevelCatalog.bundled())
        self.progressStore = progressStore
        self.store = store
        self.progress = progressStore?.load() ?? PlayerProgress()
        haptics.isEnabled = progress.settings.haptics
        // Purchases change what's unlocked: re-render anything observing the model.
        store.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var hasFullGame: Bool { store.hasFullGame }

    func level(_ id: String) -> LevelDefinition? { catalog.levels[id] }

    func isUnlocked(_ id: String) -> Bool { progress.isUnlocked(id, in: catalog, fullGame: hasFullGame) }

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

    func record(levelID: String, stars: Int) {
        guard progress.record(levelID: levelID, stars: stars) else { return }
        save()
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

    private func save() {
        do { try progressStore?.save(progress) } catch { assertionFailure("save failed: \(error)") }
    }
}

import GameKit
import GrainfallCore
import UIKit

/// Game Center: one leaderboard (total stars) and per-chapter achievements. Entirely optional —
/// if the player isn't signed in, every call is a silent no-op.
///
/// IDs must be created in App Store Connect (see docs/05-launch.md).
@MainActor
final class GameCenter {
    static let starsLeaderboard = "grainfall.total_stars"
    static func chapterComplete(_ id: Int) -> String { "grainfall.chapter\(id).complete" }
    static func chapterPerfect(_ id: Int) -> String { "grainfall.chapter\(id).perfect" }

    private(set) var isAuthenticated = false

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, _ in
            MainActor.assumeIsolated {
                if let viewController { Self.present(viewController) }
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                if GKLocalPlayer.local.isAuthenticated {
                    GKAccessPoint.shared.location = .topLeading
                }
            }
        }
    }

    /// Shows or hides the floating Game Center access point (title screen only).
    func showAccessPoint(_ visible: Bool) {
        GKAccessPoint.shared.isActive = visible && isAuthenticated
    }

    func report(progress: PlayerProgress, catalog: LevelCatalog) {
        guard isAuthenticated else { return }
        let total = progress.totalStars(in: catalog)
        Task {
            try? await GKLeaderboard.submitScore(total, context: 0, player: GKLocalPlayer.local,
                                                 leaderboardIDs: [Self.starsLeaderboard])
        }
        var achievements: [GKAchievement] = []
        for chapter in catalog.chapters {
            let done = chapter.levels.filter(progress.isCompleted).count
            let complete = GKAchievement(identifier: Self.chapterComplete(chapter.id))
            complete.percentComplete = 100 * Double(done) / Double(max(1, chapter.levels.count))
            complete.showsCompletionBanner = true
            achievements.append(complete)
            if progress.isPerfect(chapter) {
                let perfect = GKAchievement(identifier: Self.chapterPerfect(chapter.id))
                perfect.percentComplete = 100
                perfect.showsCompletionBanner = true
                achievements.append(perfect)
            }
        }
        GKAchievement.report(achievements) { _ in }
    }

    private static func present(_ vc: UIViewController) {
        let root = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        var top = root
        while let presented = top?.presentedViewController { top = presented }
        top?.present(vc, animated: true)
    }
}

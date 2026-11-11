import UIKit

/// Throttled haptics (PRD §6: light while digging, firm on gates, success/failure on results).
@MainActor
final class Haptics {
    var isEnabled = true

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notify = UINotificationFeedbackGenerator()
    private var lastDig = 0.0

    func dig() {
        guard isEnabled else { return }
        let now = CACurrentMediaTime()
        guard now - lastDig > 0.06 else { return }
        lastDig = now
        light.impactOccurred(intensity: 0.5)
    }

    func gate() { if isEnabled { rigid.impactOccurred() } }
    func success() { if isEnabled { notify.notificationOccurred(.success) } }
    func failure() { if isEnabled { notify.notificationOccurred(.error) } }
}

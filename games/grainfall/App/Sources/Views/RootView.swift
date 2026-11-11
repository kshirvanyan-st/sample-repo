import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            switch model.screen {
            case .title:
                TitleView().transition(.opacity)
            case .levels:
                LevelSelectView().transition(.opacity)
            case let .game(id):
                if let level = model.level(id) {
                    GameScreen(level: level, autoplay: model.autoplay && id == model.launchLevel)
                        .id(id).transition(.opacity)
                }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: model.screen)
        .sheet(isPresented: $model.showPaywall) { PaywallView() }
        .sheet(isPresented: $model.showSettings) { SettingsView() }
    }
}

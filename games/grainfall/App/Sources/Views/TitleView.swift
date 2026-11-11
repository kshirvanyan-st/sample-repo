import GrainfallCore
import SwiftUI

struct TitleView: View {
    @EnvironmentObject private var model: AppModel
    @StateObject private var demo: GameController

    @MainActor init() {
        // Autoclosure: evaluated once per view identity, not on every parent re-render.
        _demo = StateObject(wrappedValue: TitleView.makeDemo())
    }

    /// The title screen plays a looping demo of a level's reference solution.
    @MainActor private static func makeDemo() -> GameController {
        let fallback = LevelDefinition(id: "demo", name: "", shapes: [], spouts: [],
                                       cups: [CupDef(x: 0, y: 0, w: 1, h: 1, accepts: .sand, required: 1)])
        let level = (try? LevelCatalog.bundled())?.levels["1-4"] ?? fallback
        return GameController(level: level, demo: true)
    }

    var body: some View {
        ZStack {
            GridView(controller: demo, interactive: false)
                .ignoresSafeArea()
                .opacity(0.55)
                .accessibilityHidden(true)

            VStack(spacing: 14) {
                Spacer()
                Text("GRAINFALL")
                    .font(Theme.title(44))
                    .foregroundStyle(Theme.sand)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 3, y: 3)
                    .accessibilityAddTraits(.isHeader)
                Text("A pixel physics puzzle")
                    .font(Theme.body)
                    .foregroundStyle(Theme.text)
                Spacer()
                VStack(spacing: 12) {
                    Button(model.progress.bestStars.isEmpty ? "Play" : "Continue") {
                        if let id = model.continueLevel { model.play(id) }
                    }
                    .buttonStyle(PixelButtonStyle())
                    Button("Levels") { model.screen = .levels }
                        .buttonStyle(PixelButtonStyle(prominent: false))
                }
                .padding(.horizontal, 48)
                Button {
                    model.showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                        .font(Theme.body)
                        .foregroundStyle(Theme.dim)
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
    }
}

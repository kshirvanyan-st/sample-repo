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
        // A showcase level with lava glow, fire and water — the title screen is the first impression.
        let catalog = try? LevelCatalog.bundled()
        let level = ["4-1", "3-2", "1-4"].lazy.compactMap { catalog?.levels[$0] }.first ?? fallback
        return GameController(level: level, demo: true)
    }

    var body: some View {
        content
            .onAppear { model.gameCenter.showAccessPoint(true) }
            .onDisappear { model.gameCenter.showAccessPoint(false) }
    }

    private var content: some View {
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
                Text("Dig. Pour. Solve.")
                    .font(Theme.body)
                    .foregroundStyle(Theme.text)
                Spacer()
                VStack(spacing: 12) {
                    Button(model.progress.bestStars.isEmpty ? LocalizedStringKey("Play") : LocalizedStringKey("Continue")) {
                        if let id = model.continueLevel { model.play(id) }
                    }
                    .buttonStyle(PixelButtonStyle())
                    Button("Levels") { model.screen = .levels }
                        .buttonStyle(PixelButtonStyle(prominent: false))
                }
                .padding(.horizontal, 48)
                if !model.hasFullGame {
                    Text("\(model.catalog.chapters.filter(\.free).count) chapters free")
                        .font(.footnote).foregroundStyle(Theme.dim)
                }
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

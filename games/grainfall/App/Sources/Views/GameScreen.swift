import GrainfallCore
import SwiftUI

/// Gameplay: Metal board + HUD + overlays (spec §5).
struct GameScreen: View {
    @EnvironmentObject private var model: AppModel
    @StateObject private var game: GameController
    @State private var showHint = false
    @State private var result: GameStatus?

    private let hudHeight: CGFloat = 96
    private let meterHeight: CGFloat = 36

    @MainActor init(level: LevelDefinition) {
        _game = StateObject(wrappedValue: GameController(level: level))
    }

    var body: some View {
        GeometryReader { geo in
            let top = geo.safeAreaInsets.top + hudHeight
            let bottom = geo.safeAreaInsets.bottom + meterHeight
            ZStack(alignment: .top) {
                GridView(controller: game, insets: (Double(top), Double(bottom)))
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    digMeter
                }

                overlays
            }
        }
        .onAppear(perform: setUp)
    }

    private func setUp() {
        game.haptics = model.haptics
        game.onFinished = { status, stars in
            if status == .won { model.record(levelID: game.level.id, stars: stars) }
            result = status
        }
        if game.level.hint != nil, !model.progress.seenHints.contains(game.level.id) {
            showHint = true
        }
    }

    // MARK: HUD

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                iconButton("chevron.left", label: "Levels") { model.screen = .levels }
                Spacer()
                VStack(spacing: 2) {
                    Text(game.level.id).font(Theme.title(13)).foregroundStyle(Theme.dim)
                    Text(game.level.name).font(Theme.body).foregroundStyle(Theme.text)
                }
                .accessibilityElement(children: .combine)
                Spacer()
                iconButton("arrow.counterclockwise", label: "Restart") { restart() }
                iconButton("pause.fill", label: "Pause") { game.isPaused = true }
            }
            HStack(spacing: 10) {
                ForEach(game.hud.cups) { cup in
                    CupChip(cup: cup)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .frame(height: hudHeight, alignment: .top)
    }

    private var digMeter: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.point.up.left.fill").foregroundStyle(Theme.dim)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.panel)
                    Capsule().fill(Color(rgba: Palette.shades(.dirt)[2]))
                        .frame(width: g.size.width * game.hud.digRemaining)
                }
            }
            .frame(height: 10)
        }
        .padding(.horizontal, 20)
        .frame(height: meterHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dig budget")
        .accessibilityValue("\(Int(game.hud.digRemaining * 100)) percent left")
    }

    private func iconButton(_ symbol: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.text)
                .frame(width: 40, height: 40)
                .background(Theme.panel.opacity(0.8), in: RoundedRectangle(cornerRadius: 6))
        }
        .accessibilityLabel(label)
    }

    private func restart() {
        result = nil
        game.restart()
    }

    // MARK: Overlays

    @ViewBuilder
    private var overlays: some View {
        if showHint, let hint = game.level.hint {
            HintBubble(text: hint) {
                showHint = false
                model.markHintSeen(game.level.id)
            }
            .padding(.top, 140)
        }

        if game.hud.isStuck, result == nil {
            VStack {
                Spacer()
                Button("Stuck? Try again", action: restart)
                    .buttonStyle(PixelButtonStyle())
                    .padding(.horizontal, 64)
                    .padding(.bottom, 70)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        if game.isPaused {
            ModalCard {
                Text("Paused").font(Theme.title(28)).foregroundStyle(Theme.text)
                Button("Resume") { game.isPaused = false }.buttonStyle(PixelButtonStyle())
                Button("Restart", action: restart).buttonStyle(PixelButtonStyle(prominent: false))
                Button("Levels") { model.screen = .levels }.buttonStyle(PixelButtonStyle(prominent: false))
            }
        }

        if let result {
            ResultOverlay(status: result, stars: game.hud.stars, dug: game.hud.dug,
                          hasNext: model.catalog.level(after: game.level.id) != nil,
                          next: { model.playNext(after: game.level.id) },
                          retry: restart,
                          levels: { model.screen = .levels })
        }
    }
}

struct CupChip: View {
    let cup: HUDState.Cup

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: cup.material.symbol)
                .foregroundStyle(cup.material.color)
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.panel)
                Capsule().fill(cup.material.color)
                    .frame(width: 70 * cup.fraction)
            }
            .frame(width: 70, height: 8)
            Text("\(cup.collected)/\(cup.required)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.text)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.panel.opacity(0.85), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(cup.material.displayName) cup")
        .accessibilityValue("\(cup.collected) of \(cup.required)")
    }
}

struct HintBubble: View {
    let text: String
    let dismiss: () -> Void

    var body: some View {
        Button(action: dismiss) {
            HStack(spacing: 10) {
                Image(systemName: "hand.draw.fill").font(.title2)
                Text(text).font(Theme.body).multilineTextAlignment(.leading)
            }
            .foregroundStyle(Theme.background)
            .padding(14)
            .background(Theme.sand, in: RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 32)
        .accessibilityHint("Dismisses the hint")
    }
}

struct ModalCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 14) { content }
                .padding(24)
                .frame(maxWidth: 320)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.sand.opacity(0.4), lineWidth: 2))
                .padding(32)
        }
    }
}

struct ResultOverlay: View {
    let status: GameStatus
    let stars: Int
    let dug: Int
    let hasNext: Bool
    let next: () -> Void
    let retry: () -> Void
    let levels: () -> Void

    var body: some View {
        ModalCard {
            switch status {
            case .won:
                Text("Poured!").font(Theme.title(30)).foregroundStyle(Theme.sand)
                StarsView(stars: stars, size: 34)
                Text("Dug \(dug) cells").font(.footnote).foregroundStyle(Theme.dim)
                if hasNext {
                    Button("Next level", action: next).buttonStyle(PixelButtonStyle())
                }
                Button("Replay", action: retry).buttonStyle(PixelButtonStyle(prominent: false))
                Button("Levels", action: levels).buttonStyle(PixelButtonStyle(prominent: false))
            case let .failed(.contaminated(_, by)):
                Text("Ruined!").font(Theme.title(30)).foregroundStyle(Color(rgba: Palette.shades(.lava)[0]))
                Text("\(by.displayName) got into the cup.")
                    .font(Theme.body).foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                Button("Try again", action: retry).buttonStyle(PixelButtonStyle())
                Button("Levels", action: levels).buttonStyle(PixelButtonStyle(prominent: false))
            case .playing:
                EmptyView()
            }
        }
    }
}

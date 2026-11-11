import GrainfallCore
import StoreKit
import SwiftUI

/// Gameplay: Metal board + HUD + overlays (spec §5).
struct GameScreen: View {
    @EnvironmentObject private var model: AppModel
    @StateObject private var game: GameController
    @Environment(\.requestReview) private var requestReview
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showHint = false
    @State private var showGhost = false
    @State private var showIntro = true
    @State private var result: GameStatus?
    @State private var newBest = false
    @State private var shake: CGFloat = 0

    private let hudHeight: CGFloat = 100
    private let meterHeight: CGFloat = 44

    @MainActor init(level: LevelDefinition, autoplay: Bool = false) {
        _game = StateObject(wrappedValue: GameController(level: level, demo: autoplay))
    }

    /// Hints unlock after a restart or 15 s of play, so players get a fair try first.
    private var hintAvailable: Bool { !game.ghost.isEmpty && (game.attempts > 1 || game.hud.seconds > 15) }
    private var showTutorial: Bool {
        !game.isDemo && game.level.id == model.catalog.orderedLevelIDs.first && !game.hasTouched
            && !model.progress.seenHints.contains("tutorial")
    }

    var body: some View {
        GeometryReader { geo in
            let top = geo.safeAreaInsets.top + hudHeight
            let bottom = geo.safeAreaInsets.bottom + meterHeight
            let box = Letterbox(viewWidth: geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                                viewHeight: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom,
                                topInset: top, bottomInset: bottom)
            ZStack(alignment: .top) {
                ZStack {
                    GridView(controller: game, insets: (Double(top), Double(bottom)))
                    if showGhost || showTutorial {
                        GhostOverlay(strokes: showTutorial ? Array(game.ghost.prefix(1)) : game.ghost,
                                     box: box, animateHand: showTutorial)
                            .allowsHitTesting(false)
                    }
                }
                .modifier(ShakeEffect(amount: reduceMotion ? 0 : 6, animatableData: shake))
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    bottomBar
                }

                overlays
            }
        }
        .onAppear(perform: setUp)
        .onDisappear { model.audio.quiet() }
        .onChange(of: game.shakeCount) { _, _ in
            withAnimation(.linear(duration: 0.35)) { shake += 1 }
        }
        .onChange(of: game.hasTouched) { _, touched in
            if touched, game.level.id == model.catalog.orderedLevelIDs.first { model.markHintSeen("tutorial") }
        }
    }

    private func setUp() {
        game.haptics = model.haptics
        game.audio = model.audio
        game.onFinished = { status, stars in
            newBest = status == .won && model.record(levelID: game.level.id, stars: stars)
            showGhost = false
            withAnimation(.spring(duration: 0.35)) { result = status }
            if model.wantsReview {
                model.wantsReview = false
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    requestReview()
                }
            }
        }
        if !game.isDemo, game.level.hint != nil, !model.progress.seenHints.contains(game.level.id), !showTutorial {
            showHint = true
        }
        Task {
            try? await Task.sleep(for: .seconds(1.3))
            withAnimation(.easeOut(duration: 0.4)) { showIntro = false }
        }
    }

    // MARK: HUD

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                iconButton("chevron.left", label: "Levels") { model.screen = .levels }
                Spacer()
                VStack(spacing: 2) {
                    Text(game.level.id).font(Theme.title(13)).foregroundStyle(Theme.dim)
                    Text(LocalizedStringKey(game.level.name)).font(Theme.body).foregroundStyle(Theme.text)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                .accessibilityElement(children: .combine)
                Spacer()
                iconButton("arrow.counterclockwise", label: "Restart") { restart() }
                iconButton("pause.fill", label: "Pause") { game.isPaused = true }
            }
            HStack(spacing: 8) {
                ForEach(game.hud.cups) { cup in CupChip(cup: cup) }
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .frame(height: hudHeight, alignment: .top)
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.point.up.left.fill").foregroundStyle(Theme.dim)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.panel)
                    Capsule().fill(Color(rgba: Palette.shades(.dirt)[2]))
                        .frame(width: g.size.width * game.hud.digRemaining)
                }
            }
            .frame(height: 10)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Dig budget")
            .accessibilityValue("\(Int(game.hud.digRemaining * 100)) percent left")

            if game.level.blasts > 0 {
                Button {
                    game.blastArmed.toggle()
                    model.audio.play(.tap)
                } label: {
                    Label("\(game.hud.blastsLeft)", systemImage: "burst.fill")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .foregroundStyle(game.blastArmed ? Theme.background : Theme.text)
                        .background(game.blastArmed ? Color.orange : Theme.panel, in: Capsule())
                }
                .disabled(game.hud.blastsLeft == 0)
                .accessibilityLabel("Blast charges: \(game.hud.blastsLeft)")
                .accessibilityHint(game.blastArmed ? "Armed. Tap the board to blast." : "Arms a blast for your next tap.")
            }

            if hintAvailable {
                Button {
                    withAnimation { showGhost.toggle() }
                    model.audio.play(.tap)
                } label: {
                    Image(systemName: showGhost ? "lightbulb.fill" : "lightbulb")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(showGhost ? Theme.sand : Theme.text)
                        .frame(width: 38, height: 34)
                        .background(Theme.panel, in: Capsule())
                }
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel(showGhost ? "Hide hint" : "Show hint")
            }
        }
        .padding(.horizontal, 20)
        .frame(height: meterHeight)
        .animation(.spring(duration: 0.3), value: hintAvailable)
    }

    private func iconButton(_ symbol: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button {
            model.audio.play(.tap)
            action()
        } label: {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.text)
                .frame(width: 44, height: 44)
                .background(Theme.panel.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityLabel(label)
    }

    private func restart() {
        result = nil
        newBest = false
        game.restart()
    }

    // MARK: Overlays

    @ViewBuilder
    private var overlays: some View {
        if showIntro {
            VStack(spacing: 6) {
                Text(game.level.id).font(Theme.title(18)).foregroundStyle(Theme.dim)
                Text(LocalizedStringKey(game.level.name)).font(Theme.title(30)).foregroundStyle(Theme.sand)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 220)
            .shadow(color: .black, radius: 0, x: 2, y: 2)
            .allowsHitTesting(false)
            .transition(.opacity.combined(with: .scale(scale: 1.1)))
        }

        if showTutorial {
            Text("Drag to dig a path for the sand")
                .font(Theme.body)
                .foregroundStyle(Theme.background)
                .padding(12)
                .background(Theme.sand, in: RoundedRectangle(cornerRadius: 8))
                .padding(.top, 150)
                .allowsHitTesting(false)
        } else if showHint, let hint = game.level.hint {
            HintBubble(text: hint) {
                showHint = false
                model.markHintSeen(game.level.id)
            }
            .padding(.top, 150)
        }

        if game.hud.isStuck, result == nil {
            VStack {
                Spacer()
                Button("Stuck? Try again", action: restart)
                    .buttonStyle(PixelButtonStyle())
                    .padding(.horizontal, 64)
                    .padding(.bottom, 80)
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
            ResultOverlay(status: result, stars: game.hud.stars, dug: game.hud.dug, newBest: newBest,
                          chapterDone: model.justCompletedChapter,
                          levelID: game.level.id,
                          snapshot: result == .won ? game.snapshot() : nil,
                          hasNext: model.catalog.level(after: game.level.id) != nil,
                          next: {
                              model.justCompletedChapter = nil
                              model.playNext(after: game.level.id)
                          },
                          retry: restart,
                          levels: {
                              model.justCompletedChapter = nil
                              model.screen = .levels
                          })
            .transition(.opacity.combined(with: .scale(scale: 0.92)))
        }
    }
}

/// Horizontal shake driven by an incrementing counter.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * 6), y: 0))
    }
}

/// Draws the reference solution (dig paths, gate taps, blasts) over the board.
struct GhostOverlay: View {
    let strokes: [GhostStroke]
    let box: Letterbox
    var animateHand = false

    private func point(_ p: Point) -> CGPoint {
        CGPoint(x: CGFloat(box.x + (Double(p.x) + 0.5) * box.scale),
                y: CGFloat(box.y + (Double(p.y) + 0.5) * box.scale))
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, _ in
                for stroke in strokes {
                    switch stroke.kind {
                    case .dig:
                        var path = Path()
                        path.addLines(stroke.points.map(point))
                        let width = CGFloat(Double(World.digRadius) * 2 * box.scale)
                        ctx.stroke(path, with: .color(.white.opacity(0.18)),
                                   style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                        ctx.stroke(path, with: .color(.white.opacity(0.8)),
                                   style: StrokeStyle(lineWidth: 2, lineCap: .round,
                                                      dash: [6, 6], dashPhase: -CGFloat(t * 24)))
                    case .gate, .blast:
                        let c = point(stroke.points[0])
                        let r = CGFloat(10 + 4 * sin(t * 5))
                        let ring = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                        ctx.stroke(ring, with: .color(stroke.kind == .gate ? Theme.sand : .orange), lineWidth: 3)
                    }
                }
                if animateHand, let first = strokes.first(where: { $0.kind == .dig }), first.points.count > 1 {
                    let pts = first.points.map(point)
                    let cycle = 2.4
                    let f = (t.truncatingRemainder(dividingBy: cycle)) / cycle
                    let p = position(along: pts, fraction: min(1, f * 1.25))
                    ctx.draw(Image(systemName: "hand.point.up.left.fill"), at: CGPoint(x: p.x + 14, y: p.y + 18),
                             anchor: .topLeading)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func position(along pts: [CGPoint], fraction: Double) -> CGPoint {
        var lengths: [CGFloat] = []
        for i in 1..<pts.count { lengths.append(hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y)) }
        var remaining = lengths.reduce(0, +) * CGFloat(fraction)
        for i in 1..<pts.count {
            if remaining <= lengths[i - 1] {
                let k = lengths[i - 1] == 0 ? 0 : remaining / lengths[i - 1]
                return CGPoint(x: pts[i - 1].x + (pts[i].x - pts[i - 1].x) * k,
                               y: pts[i - 1].y + (pts[i].y - pts[i - 1].y) * k)
            }
            remaining -= lengths[i - 1]
        }
        return pts.last ?? .zero
    }
}

struct CupChip: View {
    let cup: HUDState.Cup

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: cup.fraction >= 1 ? "checkmark.circle.fill" : cup.material.symbol)
                .foregroundStyle(cup.material.color)
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.panel)
                Capsule().fill(cup.material.color)
                    .frame(width: 64 * cup.fraction)
            }
            .frame(width: 64, height: 8)
            Text("\(cup.collected)/\(cup.required)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.text)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.panel.opacity(0.85), in: Capsule())
        .animation(.easeOut(duration: 0.2), value: cup.fraction >= 1)
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
                Image(systemName: "lightbulb.fill").font(.title3)
                Text(LocalizedStringKey(text)).font(Theme.body).multilineTextAlignment(.leading)
                Image(systemName: "xmark").font(.caption.weight(.bold)).opacity(0.6)
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
                .frame(maxWidth: 340)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.sand.opacity(0.4), lineWidth: 2))
                .padding(28)
        }
    }
}

struct ResultOverlay: View {
    let status: GameStatus
    let stars: Int
    let dug: Int
    let newBest: Bool
    let chapterDone: Chapter?
    let levelID: String
    let snapshot: UIImage?
    let hasNext: Bool
    let next: () -> Void
    let retry: () -> Void
    let levels: () -> Void

    @State private var shownStars = 0

    var body: some View {
        ModalCard {
            switch status {
            case .won:
                if let chapterDone {
                    Text("Chapter \(chapterDone.id) complete!")
                        .font(Theme.title(15)).foregroundStyle(Theme.background)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Theme.sand, in: Capsule())
                }
                Text("Poured!").font(Theme.title(32)).foregroundStyle(Theme.sand)
                StarsView(stars: shownStars, size: 36)
                    .onAppear(perform: revealStars)
                HStack(spacing: 6) {
                    Text("Dug \(dug) cells").font(.footnote).foregroundStyle(Theme.dim)
                    if newBest {
                        Text("New best").font(.footnote.weight(.bold)).foregroundStyle(Theme.sand)
                    }
                }
                if stars < 3 {
                    Text("Dig less for more stars").font(.caption).foregroundStyle(Theme.dim)
                }
                if hasNext {
                    Button("Next level", action: next).buttonStyle(PixelButtonStyle())
                }
                HStack(spacing: 10) {
                    Button("Replay", action: retry).buttonStyle(PixelButtonStyle(prominent: false))
                    if let snapshot {
                        let image = Image(uiImage: snapshot)
                        ShareLink(item: image,
                                  message: Text("I solved level \(levelID) of Grainfall with \(stars) ★"),
                                  preview: SharePreview("Grainfall \(levelID)", image: image)) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .buttonStyle(PixelButtonStyle(prominent: false))
                        .frame(width: 70)
                        .accessibilityLabel("Share")
                    }
                }
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

    private func revealStars() {
        for i in 1...max(1, stars) where i <= stars {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 * Double(i)) {
                withAnimation(.spring(duration: 0.3, bounce: 0.5)) { shownStars = i }
            }
        }
    }
}

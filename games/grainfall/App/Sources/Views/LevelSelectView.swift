import GrainfallCore
import SwiftUI

struct LevelSelectView: View {
    @EnvironmentObject private var model: AppModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { model.screen = .title } label: {
                    Image(systemName: "chevron.left").font(.title2.weight(.bold))
                }
                .accessibilityLabel("Back")
                Spacer()
                Label("\(model.progress.totalStars(in: model.catalog))", systemImage: "star.fill")
                    .font(Theme.body)
                    .foregroundStyle(Theme.sand)
                    .accessibilityLabel("\(model.progress.totalStars(in: model.catalog)) stars collected")
            }
            .foregroundStyle(Theme.text)
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(model.catalog.chapters, id: \.id) { chapter in
                        chapterSection(chapter)
                    }
                    Text("More chapters coming soon")
                        .font(.footnote)
                        .foregroundStyle(Theme.dim)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }

    @ViewBuilder
    private func chapterSection(_ chapter: Chapter) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(chapter.id). \(Text(LocalizedStringKey(chapter.name)))")
                    .font(Theme.title(20))
                    .foregroundStyle(Theme.text)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                let earned = chapter.levels.reduce(0) { $0 + model.progress.stars($1) }
                Label("\(earned)/\(chapter.levels.count * 3)", systemImage: "star.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(model.progress.isPerfect(chapter) ? Theme.sand : Theme.dim)
                if model.needsPurchase(chapter) {
                    Button("Unlock") { model.showPaywall = true }
                        .font(Theme.body)
                        .foregroundStyle(Theme.sand)
                }
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(chapter.levels.enumerated()), id: \.element) { index, id in
                    levelTile(id: id, number: index + 1, chapter: chapter)
                }
            }
        }
    }

    private func levelTile(id: String, number: Int, chapter: Chapter) -> some View {
        let unlocked = model.isUnlocked(id)
        let stars = model.progress.stars(id)
        return Button {
            if unlocked { model.play(id) } else if model.needsPurchase(chapter) { model.showPaywall = true }
        } label: {
            VStack(spacing: 6) {
                if unlocked {
                    Text("\(number)").font(Theme.title(22))
                    StarsView(stars: stars, size: 10)
                } else {
                    Image(systemName: "lock.fill").font(.title3)
                }
            }
            .foregroundStyle(unlocked ? Theme.text : Theme.dim)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(stars == 3 ? Theme.sand.opacity(0.7) : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(unlocked
            ? Text("Level \(id), \(Text(LocalizedStringKey(model.level(id)?.name ?? ""))), \(stars) stars")
            : Text("Level \(id), locked"))
    }
}

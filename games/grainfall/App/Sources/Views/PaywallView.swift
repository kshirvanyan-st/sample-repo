import StoreKit
import SwiftUI

/// Shown only when the player taps a locked paid chapter (PRD §5.6) — never mid-level.
struct PaywallView: View {
    @EnvironmentObject private var store: StoreService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Capsule().fill(Theme.dim.opacity(0.4)).frame(width: 40, height: 5).padding(.top, 8)
            Spacer(minLength: 0)
            Image(systemName: "flame.fill")
                .font(.system(size: 54))
                .foregroundStyle(Color(rgba: .init(hex: 0xFF5A1F)))
                .accessibilityHidden(true)
            Text("Grainfall Full Game").font(Theme.title(24)).foregroundStyle(Theme.text)
            VStack(alignment: .leading, spacing: 10) {
                feature("square.grid.3x3.fill", "Unlock every chapter: lava, stone, fire and more")
                feature("sparkles", "All future chapters included")
                feature("hand.raised.fill", "One purchase. No ads, ever.")
                feature("person.2.fill", "Shared with your family via Family Sharing")
            }
            .padding(.vertical, 8)
            Spacer(minLength: 0)

            if store.hasFullGame {
                Label("Unlocked — thank you!", systemImage: "checkmark.seal.fill")
                    .font(Theme.body).foregroundStyle(Theme.sand)
                Button("Done") { dismiss() }.buttonStyle(PixelButtonStyle())
            } else {
                Button {
                    Task { await store.purchase() }
                } label: {
                    if store.state == .purchasing {
                        ProgressView().tint(Theme.background)
                    } else {
                        Text(store.product.map { "Unlock for \($0.displayPrice)" } ?? "Unlock Full Game")
                    }
                }
                .buttonStyle(PixelButtonStyle())
                .disabled(store.state == .purchasing)

                Button("Restore Purchases") { Task { await store.restore() } }
                    .font(Theme.body)
                    .foregroundStyle(Theme.dim)
            }

            if case let .failed(message) = store.state {
                Text(message).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
            } else if store.state == .pending {
                Text("Purchase pending approval.").font(.footnote).foregroundStyle(Theme.dim)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .onChange(of: store.hasFullGame) { _, owned in if owned { dismiss() } }
    }

    private func feature(_ symbol: String, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(Theme.sand).frame(width: 24)
            Text(text).font(Theme.body).foregroundStyle(Theme.text)
        }
    }
}

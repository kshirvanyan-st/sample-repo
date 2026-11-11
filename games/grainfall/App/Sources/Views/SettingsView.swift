import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var store: StoreService
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    private var version: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "1.0") (\(info?["CFBundleVersion"] as? String ?? "1"))"
    }

    private func binding(_ get: @escaping () -> Bool, _ set: @escaping (Bool) -> Void) -> Binding<Bool> {
        Binding(get: get, set: set)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sound & feel") {
                    Toggle("Sound effects", isOn: binding({ model.progress.settings.sound }, model.setSound))
                    Toggle("Music", isOn: binding({ model.progress.settings.music }, model.setMusic))
                    Toggle("Haptics", isOn: binding({ model.progress.settings.haptics }, model.setHaptics))
                }
                Section("Purchases") {
                    if store.hasFullGame {
                        Label("Full Game unlocked", systemImage: "checkmark.seal.fill")
                    } else {
                        Button("Unlock Full Game") {
                            dismiss()
                            model.showPaywall = true
                        }
                    }
                    Button("Restore Purchases") { Task { await store.restore() } }
                }
                Section("Progress") {
                    LabeledContent("Stars", value: "\(model.progress.totalStars(in: model.catalog)) / \(model.catalog.orderedLevelIDs.count * 3)")
                    Button("Reset Progress", role: .destructive) { confirmReset = true }
                }
                Section("About") {
                    LabeledContent("Version", value: version)
                    Text("Grainfall collects no data. Your progress stays on this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Sound and music are generated live on your device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Reset all stars and progress?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset Progress", role: .destructive) { model.resetProgress() }
            } message: {
                Text("Purchases are not affected.")
            }
        }
    }
}

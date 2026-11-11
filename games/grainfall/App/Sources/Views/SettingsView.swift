import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var store: StoreService
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "1.0") (\(info?["CFBundleVersion"] as? String ?? "1"))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Feel") {
                    Toggle("Haptics", isOn: Binding(get: { model.progress.settings.haptics },
                                                    set: { model.setHaptics($0) }))
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
                Section("About") {
                    LabeledContent("Version", value: version)
                    Text("Grainfall collects no data. Your progress stays on this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

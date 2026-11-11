import SwiftUI

@main
struct GrainfallApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .environmentObject(model.store)
                .task {
                    model.start()
                    await model.store.load()
                }
                .preferredColorScheme(.dark)
                .statusBarHidden()
        }
    }
}

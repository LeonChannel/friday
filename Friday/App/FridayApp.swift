import SwiftUI

@main
struct FridayApp: App {
    @State private var projects = ProjectStore.live()

    var body: some Scene {
        WindowGroup("Friday") {
            RootView()
                .environment(projects)
                .frame(minWidth: 900, minHeight: 560)
        }
    }
}

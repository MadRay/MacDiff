import SwiftUI

@main
struct MacDiffApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1200, height: 760)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

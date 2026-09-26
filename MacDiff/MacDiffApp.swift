import SwiftUI
import AppKit

@main
struct MacDiffApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 760)
        .commands {
            CommandGroup(replacing: .newItem) { }
            ModeCommands()
            HelpCommands()
        }

        Window("MacDiff Help", id: "help") {
            HelpView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

// MARK: - Mode menu commands

private struct ModeCommands: Commands {
    @FocusedBinding(\.selectedAppMode) private var selectedMode

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            ForEach(AppMode.allCases) { mode in
                Button(mode.rawValue) {
                    selectedMode = mode
                }
                .keyboardShortcut(KeyEquivalent(mode.shortcut), modifiers: .command)
                .disabled(selectedMode == nil)
            }
        }
    }
}

// MARK: - Help menu

private struct HelpCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("MacDiff Help") {
                openWindow(id: "help")
            }
            .keyboardShortcut("?", modifiers: .command)
        }
    }
}

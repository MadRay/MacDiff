// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacDiff",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MacDiff",
            path: "MacDiff",
            sources: [
                "MacDiffApp.swift",
                "Theme/DiffTheme.swift",
                "Models/DiffModels.swift",
                "Models/DiffEngine.swift",
                "Models/JSONNormalizer.swift",
                "ViewModels/DiffViewModel.swift",
                "Views/ContentView.swift",
                "Views/AppToolbarView.swift",
                "Views/ToolbarStatusPills.swift",
                "Views/FooterStatsBar.swift",
                "Views/DiffPaneView.swift",
                "Views/SyncedScrollTextView.swift",
                "Views/TextInputModeView.swift",
                "Views/FileModeView.swift",
                "Views/DropZoneView.swift",
            ],
            resources: [
                .copy("Resources/AppIcon.icns"),
            ]
        )
    ]
)

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
                "Models/DiffModels.swift",
                "Models/DiffEngine.swift",
                "Models/JSONNormalizer.swift",
                "ViewModels/DiffViewModel.swift",
                "Views/ContentView.swift",
                "Views/SummaryBannerView.swift",
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

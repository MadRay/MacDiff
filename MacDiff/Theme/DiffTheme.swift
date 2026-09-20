import SwiftUI
import AppKit

/// Adaptive light/dark palette derived from the Wonder MacDiff mockups.
enum DiffTheme {

    // MARK: - Surfaces (SwiftUI)

    static var toolbarBackground: Color {
        Color(nsColor: .init(name: "MacDiffToolbarBG", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.165, green: 0.165, blue: 0.180, alpha: 1) // #2a2a2e
                : NSColor(srgbRed: 0.910, green: 0.910, blue: 0.922, alpha: 1) // #e8e8eb
        }))
    }

    static var paneHeaderBackground: Color {
        Color(nsColor: .init(name: "MacDiffPaneHeaderBG", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.145, green: 0.145, blue: 0.157, alpha: 1) // #252528
                : NSColor(srgbRed: 0.953, green: 0.953, blue: 0.961, alpha: 1) // #f3f3f5
        }))
    }

    static var footerBackground: Color {
        toolbarBackground
    }

    static var canvasBackground: Color {
        Color(nsColor: .init(name: "MacDiffCanvasBG", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.118, green: 0.118, blue: 0.125, alpha: 1) // #1e1e20
                : NSColor.white
        }))
    }

    static var iconTileBackground: Color {
        Color(nsColor: .init(name: "MacDiffIconTileBG", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.200, green: 0.200, blue: 0.220, alpha: 1) // #333338
                : NSColor(srgbRed: 0.918, green: 0.918, blue: 0.933, alpha: 1) // #eaeaee
        }))
    }

    static var badgeBackground: Color {
        Color(nsColor: .init(name: "MacDiffBadgeBG", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.224, green: 0.224, blue: 0.243, alpha: 1) // #39393e
                : NSColor(srgbRed: 0.929, green: 0.929, blue: 0.941, alpha: 1) // #ededf0
        }))
    }

    static var separator: Color {
        Color(nsColor: .init(name: "MacDiffSeparator", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.220, green: 0.220, blue: 0.235, alpha: 1) // #38383c
                : NSColor(srgbRed: 0.882, green: 0.882, blue: 0.894, alpha: 1) // #e1e1e4
        }))
    }

    static var secondaryLabel: Color {
        Color(nsColor: .init(name: "MacDiffSecondary", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.596, green: 0.596, blue: 0.616, alpha: 1) // #98989d
                : NSColor(srgbRed: 0.431, green: 0.431, blue: 0.451, alpha: 1) // #6e6e73
        }))
    }

    static var tertiaryLabel: Color {
        Color(nsColor: .init(name: "MacDiffTertiary", dynamicProvider: { _ in
            NSColor(srgbRed: 0.557, green: 0.557, blue: 0.576, alpha: 1) // #8e8e93
        }))
    }

    static var workingCopyAccent: Color {
        Color(nsColor: .init(name: "MacDiffWorkingCopy", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.878, green: 0.714, blue: 0.314, alpha: 1) // #e0b650
                : NSColor(srgbRed: 0.604, green: 0.420, blue: 0.071, alpha: 1) // #9a6b12
        }))
    }

    static var jsonAccent: Color {
        Color(nsColor: .init(name: "MacDiffJSON", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.231, green: 0.510, blue: 0.965, alpha: 1) // #3b82f6
                : NSColor(srgbRed: 0.231, green: 0.510, blue: 0.965, alpha: 1)
        }))
    }

    static var addition: Color {
        Color(nsColor: .init(name: "MacDiffAddition", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.373, green: 0.796, blue: 0.518, alpha: 1) // #5fcb84
                : NSColor(srgbRed: 0.180, green: 0.620, blue: 0.357, alpha: 1) // #2e9e5b
        }))
    }

    static var deletion: Color {
        Color(nsColor: .init(name: "MacDiffDeletion", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.910, green: 0.518, blue: 0.553, alpha: 1) // #e8848d
                : NSColor(srgbRed: 0.702, green: 0.169, blue: 0.212, alpha: 1) // #b32b36
        }))
    }

    // MARK: - Diff row fills (AppKit)

    static func rowFill(for kind: DiffKind) -> NSColor? {
        switch kind {
        case .insertion:     return insertionRow
        case .deletion:      return deletionRow
        case .modification:  return modificationRow
        case .empty:         return emptyRow
        case .equal:         return nil
        }
    }

    static func gutterFill(for kind: DiffKind) -> NSColor {
        switch kind {
        case .insertion:     return insertionGutter
        case .deletion:      return deletionGutter
        case .modification:  return modificationGutter
        case .empty:         return emptyRow
        case .equal:         return gutterBackground
        }
    }

    static func gutterForeground(for kind: DiffKind) -> NSColor {
        switch kind {
        case .insertion:     return insertionForeground
        case .deletion:      return deletionForeground
        case .modification:  return modificationForeground
        case .empty, .equal: return gutterNumber
        }
    }

    static var gutterBackground: NSColor {
        .init(name: "MacDiffGutterBG", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.137, green: 0.137, blue: 0.149, alpha: 1) // #232326
                : NSColor(srgbRed: 0.980, green: 0.980, blue: 0.984, alpha: 1) // #fafafb
        })
    }

    static var gutterNumber: NSColor {
        .init(name: "MacDiffGutterNum", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.431, green: 0.431, blue: 0.451, alpha: 1) // #6e6e73
                : NSColor(srgbRed: 0.718, green: 0.718, blue: 0.741, alpha: 1) // #b7b7bd
        })
    }

    static var codeForeground: NSColor {
        .init(name: "MacDiffCodeFG", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.894, green: 0.894, blue: 0.902, alpha: 1) // #e4e4e6
                : NSColor(srgbRed: 0.114, green: 0.114, blue: 0.122, alpha: 1) // #1d1d1f
        })
    }

    private static var insertionRow: NSColor {
        .init(name: "MacDiffInsRow", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.086, green: 0.188, blue: 0.122, alpha: 1) // #16301f
                : NSColor(srgbRed: 0.906, green: 0.965, blue: 0.929, alpha: 1) // #e7f6ed
        })
    }

    private static var insertionGutter: NSColor {
        .init(name: "MacDiffInsGutter", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.118, green: 0.239, blue: 0.157, alpha: 1) // #1e3d28
                : NSColor(srgbRed: 0.851, green: 0.941, blue: 0.882, alpha: 1) // #d9f0e1
        })
    }

    private static var deletionRow: NSColor {
        .init(name: "MacDiffDelRow", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.229, green: 0.118, blue: 0.133, alpha: 1) // #3a1e22
                : NSColor(srgbRed: 0.988, green: 0.918, blue: 0.925, alpha: 1) // #fceaec
        })
    }

    private static var deletionGutter: NSColor {
        .init(name: "MacDiffDelGutter", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.290, green: 0.141, blue: 0.161, alpha: 1) // #4a2429
                : NSColor(srgbRed: 0.969, green: 0.867, blue: 0.878, alpha: 1) // #f7dde0
        })
    }

    private static var modificationRow: NSColor {
        .init(name: "MacDiffModRow", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.188, green: 0.165, blue: 0.094, alpha: 1) // #302a18
                : NSColor(srgbRed: 0.984, green: 0.949, blue: 0.871, alpha: 1) // #fbf2de
        })
    }

    private static var modificationGutter: NSColor {
        .init(name: "MacDiffModGutter", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.229, green: 0.196, blue: 0.125, alpha: 1) // #3a3220
                : NSColor(srgbRed: 0.957, green: 0.914, blue: 0.796, alpha: 1) // #f4e9cb
        })
    }

    private static var emptyRow: NSColor {
        .init(name: "MacDiffEmptyRow", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.145, green: 0.145, blue: 0.157, alpha: 0.55)
                : NSColor(srgbRed: 0.965, green: 0.965, blue: 0.973, alpha: 1) // #f6f6f8
        })
    }

    private static var insertionForeground: NSColor {
        .init(name: "MacDiffInsFG", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.490, green: 0.859, blue: 0.627, alpha: 1) // #7ddba0
                : NSColor(srgbRed: 0.180, green: 0.620, blue: 0.357, alpha: 1)
        })
    }

    private static var deletionForeground: NSColor {
        .init(name: "MacDiffDelFG", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.941, green: 0.584, blue: 0.616, alpha: 1) // #f0959d
                : NSColor(srgbRed: 0.702, green: 0.169, blue: 0.212, alpha: 1)
        })
    }

    private static var modificationForeground: NSColor {
        .init(name: "MacDiffModFG", dynamicProvider: { appearance in
            appearance.isDarkMacDiff
                ? NSColor(srgbRed: 0.847, green: 0.698, blue: 0.290, alpha: 1) // #d8b24a
                : NSColor(srgbRed: 0.753, green: 0.569, blue: 0.184, alpha: 1) // #c0912f
        })
    }
}

private extension NSAppearance {
    var isDarkMacDiff: Bool {
        bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}

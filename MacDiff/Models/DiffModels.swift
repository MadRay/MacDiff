import Foundation

// MARK: - Enums

enum DiffKind: Equatable {
    case equal
    case insertion
    case deletion
    case modification  // Paired change — amber highlight on both panes
    case empty         // Placeholder row for alignment
}

enum AppMode: String, CaseIterable, Identifiable {
    case text = "Text Input"
    case file = "File Diff"
    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .text: return "doc.text"
        case .file: return "doc.on.doc"
        }
    }
}

enum FileSide {
    case left, right
}

// MARK: - DiffLine

struct DiffLine: Identifiable {
    let id: UUID
    let content: String
    let kind: DiffKind
    let lineNumber: Int?   // nil for .empty placeholder rows

    init(content: String, kind: DiffKind, lineNumber: Int? = nil) {
        self.id = UUID()
        self.content = content
        self.kind = kind
        self.lineNumber = lineNumber
    }
}

// MARK: - DiffResult

struct DiffResult {
    var leftLines:  [DiffLine]
    var rightLines: [DiffLine]
    var additions:  Int
    var deletions:  Int
    var modifications: Int
    var unchanged:  Int
    var maxLineLength: Int = 0

    static let empty = DiffResult(
        leftLines: [], rightLines: [],
        additions: 0, deletions: 0, modifications: 0, unchanged: 0,
        maxLineLength: 0
    )

    var hasChanges: Bool { additions > 0 || deletions > 0 || modifications > 0 }
    var hasContent: Bool { !leftLines.isEmpty || !rightLines.isEmpty }
}

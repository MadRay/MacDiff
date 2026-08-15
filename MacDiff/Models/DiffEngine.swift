import Foundation

enum DiffEngine {

    // MARK: - Public

    static func compute(old oldText: String, new newText: String) -> DiffResult {
        let oldLines = splitLines(oldText)
        let newLines = splitLines(newText)

        guard !oldLines.isEmpty || !newLines.isEmpty else { return .empty }

        // Swift 5.1+ native Myers diff
        let diff = newLines.difference(from: oldLines)

        var removedOffsets  = Set<Int>()
        var insertedOffsets = Set<Int>()

        for change in diff {
            switch change {
            case .remove(let offset, _, _): removedOffsets.insert(offset)
            case .insert(let offset, _, _): insertedOffsets.insert(offset)
            @unknown default: break
            }
        }

        var leftLines:  [DiffLine] = []
        var rightLines: [DiffLine] = []
        var additions  = 0
        var deletions  = 0
        var unchanged  = 0

        var oldIdx = 0
        var newIdx = 0

        while oldIdx < oldLines.count || newIdx < newLines.count {
            let oldDone    = oldIdx >= oldLines.count
            let newDone    = newIdx >= newLines.count
            let isRemoved  = !oldDone && removedOffsets.contains(oldIdx)
            let isInserted = !newDone && insertedOffsets.contains(newIdx)

            if isRemoved && isInserted {
                // Paired change — show as deletion on left, insertion on right
                leftLines.append(DiffLine(content: oldLines[oldIdx], kind: .deletion,  lineNumber: oldIdx + 1))
                rightLines.append(DiffLine(content: newLines[newIdx], kind: .insertion, lineNumber: newIdx + 1))
                deletions += 1; additions += 1
                oldIdx += 1; newIdx += 1

            } else if isRemoved {
                // Deletion only — pad right with an empty placeholder
                leftLines.append(DiffLine(content: oldLines[oldIdx], kind: .deletion, lineNumber: oldIdx + 1))
                rightLines.append(DiffLine(content: "", kind: .empty))
                deletions += 1
                oldIdx += 1

            } else if isInserted {
                // Insertion only — pad left with an empty placeholder
                leftLines.append(DiffLine(content: "", kind: .empty))
                rightLines.append(DiffLine(content: newLines[newIdx], kind: .insertion, lineNumber: newIdx + 1))
                additions += 1
                newIdx += 1

            } else {
                // Equal line
                let lContent = oldDone ? "" : oldLines[oldIdx]
                let rContent = newDone ? "" : newLines[newIdx]
                leftLines.append(DiffLine(content: lContent,  kind: .equal, lineNumber: oldDone ? nil : oldIdx + 1))
                rightLines.append(DiffLine(content: rContent, kind: .equal, lineNumber: newDone ? nil : newIdx + 1))
                unchanged += 1
                if !oldDone { oldIdx += 1 }
                if !newDone { newIdx += 1 }
            }
        }

        let maxOld = oldLines.map { $0.count }.max() ?? 0
        let maxNew = newLines.map { $0.count }.max() ?? 0
        let maxLineLength = max(maxOld, maxNew)

        return DiffResult(
            leftLines: leftLines, rightLines: rightLines,
            additions: additions, deletions: deletions, unchanged: unchanged,
            maxLineLength: maxLineLength
        )
    }

    // MARK: - Private

    private static func splitLines(_ text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        var parts = text.components(separatedBy: "\n")
        if parts.last == "" { parts.removeLast() }
        return parts
    }
}

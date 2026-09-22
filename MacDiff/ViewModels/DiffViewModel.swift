import SwiftUI
import Observation

// MARK: - Scroll Sync Controller

/// Shared observable state that keeps both diff panes locked in scroll sync.
@Observable
final class ScrollSyncController {
    var offset: CGPoint = .zero
    private(set) var lastUpdatedSide: FileSide?

    /// Call this from a scroll notification; ignores sub-pixel jitter.
    func update(offset newOffset: CGPoint, from side: FileSide) {
        guard abs(newOffset.y - offset.y) > 0.5 ||
              abs(newOffset.x - offset.x) > 0.5 else { return }
        offset = newOffset
        lastUpdatedSide = side
    }

    func reset() {
        offset = .zero
        lastUpdatedSide = nil
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class DiffViewModel {

    // MARK: Inputs

    /// Raw text values bound to the text-input panes.
    /// Setting these also runs the JSON pre-processor pipeline.
    var leftText:  String = "" { didSet { processAndRecompute(side: .left) } }
    var rightText: String = "" { didSet { processAndRecompute(side: .right) } }
    var selectedMode: AppMode = .text
    var leftFilePath:  String = ""
    var rightFilePath: String = ""

    // MARK: JSON mode flags

    /// True when the left pane content was detected as valid JSON and
    /// has been normalised (pretty-printed + key-sorted).
    private(set) var leftIsJSON:  Bool = false
    /// True when the right pane content was detected as valid JSON and
    /// has been normalised (pretty-printed + key-sorted).
    private(set) var rightIsJSON: Bool = false

    // MARK: Shared scroll state

    let scrollSync = ScrollSyncController()

    // MARK: Output

    private(set) var diffResult: DiffResult = .empty

    // MARK: Private

    private var recomputeTask: Task<Void, Never>?

    /// Tracks whether we are currently applying a programmatic normalisation
    /// update, preventing infinite didSet recursion.
    private var isApplyingNormalisation = false

    // MARK: Methods

    func scheduleRecompute() {
        recomputeTask?.cancel()
        recomputeTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: 150_000_000) } catch { return }
            guard !Task.isCancelled, let self else { return }
            self.diffResult = DiffEngine.compute(old: self.leftText, new: self.rightText)
        }
    }

    /// Loads a file from `url`, runs it through the JSON pre-processor pipeline,
    /// and stores the (possibly normalised) text on the correct side.
    func loadFile(side: FileSide, url: URL) {
        guard url.isFileURL else { return }
        do {
            let rawContent = try String(contentsOf: url, encoding: .utf8)
            let (normalized, wasJSON) = JSONNormalizer.process(rawContent)

            // Update flags and content without triggering another normalisation pass
            isApplyingNormalisation = true
            switch side {
            case .left:
                leftIsJSON   = wasJSON
                leftText     = normalized
                leftFilePath = url.path
            case .right:
                rightIsJSON   = wasJSON
                rightText     = normalized
                rightFilePath = url.path
            }
            isApplyingNormalisation = false

            scheduleRecompute()
        } catch {
            print("MacDiff: failed to load \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    func clearFile(side: FileSide) {
        switch side {
        case .left:
            leftText      = ""
            leftFilePath  = ""
            leftIsJSON    = false
        case .right:
            rightText     = ""
            rightFilePath = ""
            rightIsJSON   = false
        }
    }

    func clearAll() {
        leftText  = ""; rightText  = ""
        leftFilePath  = ""; rightFilePath  = ""
        leftIsJSON    = false; rightIsJSON    = false
        diffResult    = .empty
        scrollSync.reset()
    }

    /// Swaps the left and right panes (text, file paths, and JSON flags).
    func swapPanes() {
        isApplyingNormalisation = true
        swap(&leftText, &rightText)
        swap(&leftFilePath, &rightFilePath)
        swap(&leftIsJSON, &rightIsJSON)
        isApplyingNormalisation = false
        scrollSync.reset()
        scheduleRecompute()
    }

    // MARK: - Private

    /// Called from the `didSet` observers on `leftText` / `rightText`.
    /// Runs the JSON normaliser when the change originates from user input
    /// (not from a programmatic normalisation we already applied).
    private func processAndRecompute(side: FileSide) {
        guard !isApplyingNormalisation else { return }

        let raw = side == .left ? leftText : rightText
        let (normalized, wasJSON) = JSONNormalizer.process(raw)

        if wasJSON && normalized != raw {
            // Replace the text with the normalised version; guard prevents re-entry
            isApplyingNormalisation = true
            switch side {
            case .left:  leftIsJSON = true;  leftText  = normalized
            case .right: rightIsJSON = true; rightText = normalized
            }
            isApplyingNormalisation = false
        } else {
            // Plain text or already-normalised JSON — just update the flag
            switch side {
            case .left:  leftIsJSON  = wasJSON
            case .right: rightIsJSON = wasJSON
            }
        }

        scheduleRecompute()
    }
}

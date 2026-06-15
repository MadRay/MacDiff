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

    var leftText:  String = "" { didSet { scheduleRecompute() } }
    var rightText: String = "" { didSet { scheduleRecompute() } }
    var selectedMode: AppMode = .text
    var leftFilePath:  String = ""
    var rightFilePath: String = ""

    // MARK: Shared scroll state

    let scrollSync = ScrollSyncController()

    // MARK: Output

    private(set) var diffResult: DiffResult = .empty

    // MARK: Private

    private var recomputeTask: Task<Void, Never>?

    // MARK: Methods

    func scheduleRecompute() {
        recomputeTask?.cancel()
        recomputeTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: 150_000_000) } catch { return }
            guard !Task.isCancelled, let self else { return }
            self.diffResult = DiffEngine.compute(old: self.leftText, new: self.rightText)
        }
    }

    func loadFile(side: FileSide, url: URL) {
        guard url.isFileURL else { return }
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            switch side {
            case .left:
                leftText = content
                leftFilePath = url.lastPathComponent
            case .right:
                rightText = content
                rightFilePath = url.lastPathComponent
            }
        } catch {
            print("MacDiff: failed to load \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    func clearFile(side: FileSide) {
        switch side {
        case .left:  leftText = "";  leftFilePath  = ""
        case .right: rightText = ""; rightFilePath = ""
        }
    }

    func clearAll() {
        leftText = ""; rightText = ""
        leftFilePath = ""; rightFilePath = ""
        diffResult = .empty
        scrollSync.reset()
    }
}

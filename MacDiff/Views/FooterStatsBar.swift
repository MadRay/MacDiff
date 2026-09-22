import SwiftUI

/// Bottom status bar matching the Wonder mockup footer.
struct FooterStatsBar: View {
    let diffResult: DiffResult
    var encodingLabel: String = "UTF-8 · LF"
    var isJSON: Bool = false

    private var lineCount: Int {
        max(
            diffResult.leftLines.filter { $0.kind != .empty }.count,
            diffResult.rightLines.filter { $0.kind != .empty }.count
        )
    }

    private var statsText: String {
        guard diffResult.hasContent else { return "No content" }
        return "\(lineCount) lines · \(diffResult.additions) added · \(diffResult.deletions) removed · \(diffResult.modifications) changed"
    }

    private var encodingText: String {
        isJSON ? "\(encodingLabel) · JSON" : encodingLabel
    }

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DiffTheme.tertiaryLabel)
                Text(statsText)
                    .font(.system(size: 11))
                    .foregroundStyle(DiffTheme.secondaryLabel)
                    .contentTransition(.numericText())
            }

            Spacer()

            if diffResult.hasContent {
                Text("Ready")
                    .font(.system(size: 11))
                    .foregroundStyle(DiffTheme.secondaryLabel)
            }

            Spacer()

            Text(encodingText)
                .font(.system(size: 11))
                .foregroundStyle(DiffTheme.secondaryLabel)
        }
        .padding(.horizontal, 16)
        .frame(height: 32)
        .background(DiffTheme.footerBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DiffTheme.separator)
                .frame(height: 1)
        }
        .animation(.spring(duration: 0.28), value: diffResult.additions)
        .animation(.spring(duration: 0.28), value: diffResult.deletions)
        .animation(.spring(duration: 0.28), value: diffResult.modifications)
    }
}

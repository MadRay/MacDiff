import SwiftUI

/// Compact status pills shown in the unified toolbar.
struct ToolbarStatusPills: View {
    let diffResult: DiffResult
    let isJSON: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isJSON {
                HStack(spacing: 5) {
                    Image(systemName: "curlybraces")
                        .font(.system(size: 10, weight: .semibold))
                    Text("JSON Mode")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(DiffTheme.jsonAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .strokeBorder(DiffTheme.jsonAccent.opacity(0.45), lineWidth: 1)
                        .background(Capsule().fill(DiffTheme.jsonAccent.opacity(0.08)))
                )
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }

            Text("UTF-8")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DiffTheme.secondaryLabel)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(DiffTheme.badgeBackground))

            if diffResult.hasContent {
                HStack(spacing: 10) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(DiffTheme.addition)
                            .frame(width: 6, height: 6)
                        Text("\(diffResult.additions) Addition\(diffResult.additions == 1 ? "" : "s")")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(DiffTheme.addition)
                    }

                    HStack(spacing: 5) {
                        Circle()
                            .fill(DiffTheme.deletion)
                            .frame(width: 6, height: 6)
                        Text("\(diffResult.deletions) Deletion\(diffResult.deletions == 1 ? "" : "s")")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(DiffTheme.deletion)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(DiffTheme.badgeBackground))
                .contentTransition(.numericText())
            }
        }
        .animation(.spring(duration: 0.28), value: isJSON)
        .animation(.spring(duration: 0.28), value: diffResult.additions)
        .animation(.spring(duration: 0.28), value: diffResult.deletions)
    }
}

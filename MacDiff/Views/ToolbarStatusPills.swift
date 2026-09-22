import SwiftUI

/// Individual bordered status pills matching the Wonder toolbar chrome.
struct ToolbarStatusPills: View {
    let diffResult: DiffResult
    let isJSON: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isJSON {
                StatusPill {
                    HStack(spacing: 5) {
                        Image(systemName: "curlybraces")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(DiffTheme.jsonAccent)
                        Text("JSON Mode (Normalized)")
                            .font(.system(size: 12))
                            .foregroundStyle(DiffTheme.controlLabel)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }

            StatusPill {
                Text("UTF-8")
                    .font(.system(size: 12))
                    .foregroundStyle(DiffTheme.controlLabel)
            }

            if diffResult.hasContent {
                StatusPill {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 0.204, green: 0.780, blue: 0.349)) // #34c759
                            .frame(width: 7, height: 7)
                        Text("\(diffResult.additions) Addition\(diffResult.additions == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundStyle(DiffTheme.controlLabel)

                        Text("·")
                            .font(.system(size: 12))
                            .foregroundStyle(DiffTheme.secondaryLabel.opacity(0.55))

                        Circle()
                            .fill(Color(red: 1.0, green: 0.271, blue: 0.227)) // #ff453a
                            .frame(width: 7, height: 7)
                        Text("\(diffResult.deletions) Deletion\(diffResult.deletions == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundStyle(DiffTheme.controlLabel)

                        Text("·")
                            .font(.system(size: 12))
                            .foregroundStyle(DiffTheme.secondaryLabel.opacity(0.55))

                        Circle()
                            .fill(DiffTheme.workingCopyAccent)
                            .frame(width: 7, height: 7)
                        Text("\(diffResult.modifications) Changed")
                            .font(.system(size: 12))
                            .foregroundStyle(DiffTheme.controlLabel)
                    }
                    .contentTransition(.numericText())
                }
            }
        }
        .animation(.spring(duration: 0.28), value: isJSON)
        .animation(.spring(duration: 0.28), value: diffResult.additions)
        .animation(.spring(duration: 0.28), value: diffResult.deletions)
        .animation(.spring(duration: 0.28), value: diffResult.modifications)
    }
}

private struct StatusPill<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(
                Capsule()
                    .fill(DiffTheme.controlFill)
                    .overlay(
                        Capsule()
                            .strokeBorder(DiffTheme.controlBorder, lineWidth: 1)
                    )
            )
    }
}

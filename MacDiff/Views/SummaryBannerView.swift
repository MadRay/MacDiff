import SwiftUI

struct SummaryBannerView: View {
    let diffResult: DiffResult

    private var isIdentical: Bool {
        diffResult.hasContent && !diffResult.hasChanges
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 22) {
                MetricPill(
                    value: diffResult.additions,
                    singular: "addition",
                    color: Color(red: 0.12, green: 0.76, blue: 0.47),
                    icon: "plus.circle.fill"
                )
                MetricPill(
                    value: diffResult.deletions,
                    singular: "deletion",
                    color: Color(red: 0.93, green: 0.28, blue: 0.28),
                    icon: "minus.circle.fill"
                )
                MetricPill(
                    value: diffResult.unchanged,
                    singular: "unchanged",
                    color: .secondary,
                    icon: "equal.circle.fill"
                )
            }
            .padding(.leading, 18)

            Spacer()

            if isIdentical {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color(red: 0.12, green: 0.76, blue: 0.47))
                    Text("Files are identical")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.trailing, 18)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .trailing)))
            }
        }
        .frame(height: 50)
        .background(.bar)
        .animation(.spring(duration: 0.3), value: diffResult.additions)
        .animation(.spring(duration: 0.3), value: diffResult.deletions)
        .animation(.spring(duration: 0.3), value: isIdentical)
    }
}

// MARK: - Metric Pill

private struct MetricPill: View {
    let value: Int
    let singular: String
    let color: Color
    let icon: String

    var label: String { value == 1 ? singular : "\(singular)s" }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(value > 0 ? color : Color(NSColor.tertiaryLabelColor))

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(value)")
                    .font(.system(.subheadline, design: .monospaced).weight(.bold))
                    .contentTransition(.numericText())
                    .foregroundStyle(value > 0 ? color : .secondary)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

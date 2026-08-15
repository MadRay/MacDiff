import SwiftUI

/// A header + DiffScrollView pair that represents one side of the side-by-side diff.
struct DiffPaneView: View {
    let title:      String
    let subtitle:   String
    let lines:      [DiffLine]
    let scrollSync: ScrollSyncController
    let side:          FileSide
    var isJSON:        Bool = false   // JSON mode indicator
    var maxLineLength: Int = 0

    private var changeCount: Int {
        side == .left
            ? lines.filter { $0.kind == .deletion  }.count
            : lines.filter { $0.kind == .insertion }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header bar ──────────────────────────────────────────────
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer()

                // JSON mode badge — subtle capsule shown when normalisation is active
                if isJSON {
                    JSONModeBadge()
                        .transition(.opacity.combined(with: .scale(scale: 0.88, anchor: .trailing)))
                }

                // Change badge
                if changeCount > 0 {
                    let badgeColor: Color = side == .left
                        ? Color(red: 0.93, green: 0.28, blue: 0.28)
                        : Color(red: 0.12, green: 0.76, blue: 0.47)
                    Text("\(changeCount)")
                        .font(.system(.caption2, design: .monospaced).weight(.bold))
                        .foregroundStyle(badgeColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(badgeColor.opacity(0.14)))
                        .contentTransition(.numericText())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.bar)
            .animation(.spring(duration: 0.28), value: isJSON)

            Divider()

            // ── Diff content ─────────────────────────────────────────────
            // Read scrollSync.offset here so SwiftUI registers this view
            // as a dependency — changes to offset will re-render this view,
            // which passes the new syncOffset into DiffScrollView.
            let currentOffset = scrollSync.offset

            DiffScrollView(
                lines:         lines,
                scrollSync:    scrollSync,
                syncOffset:    currentOffset,
                side:          side,
                maxLineLength: maxLineLength
            )
        }
    }
}

// MARK: - JSON Mode Badge

private struct JSONModeBadge: View {
    /// Subtle accent: a muted amber/gold that reads as "informational"
    /// without competing with the red/green diff colours.
    private let accent = Color(hue: 0.12, saturation: 0.75, brightness: 0.92)

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "curlybraces")
                .font(.system(size: 9, weight: .semibold))
            Text("JSON")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
        }
        .foregroundStyle(accent)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(accent.opacity(0.13))
                .overlay(
                    Capsule()
                        .strokeBorder(accent.opacity(0.35), lineWidth: 0.75)
                )
        )
        .help("JSON mode active — content has been normalised (pretty-printed, keys sorted)")
    }
}

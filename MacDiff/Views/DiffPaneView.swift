import SwiftUI

/// A header + DiffScrollView pair that represents one side of the side-by-side diff.
struct DiffPaneView: View {
    let title:      String
    let subtitle:   String
    let lines:      [DiffLine]
    let scrollSync: ScrollSyncController
    let side:       FileSide

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

            Divider()

            // ── Diff content ─────────────────────────────────────────────
            // Read scrollSync.offset here so SwiftUI registers this view
            // as a dependency — changes to offset will re-render this view,
            // which passes the new syncOffset into DiffScrollView.
            let currentOffset = scrollSync.offset

            DiffScrollView(
                lines:      lines,
                scrollSync: scrollSync,
                syncOffset: currentOffset,
                side:       side
            )
        }
    }
}

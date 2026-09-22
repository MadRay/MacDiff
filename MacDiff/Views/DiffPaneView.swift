import SwiftUI

/// A header + DiffScrollView pair that represents one side of the side-by-side diff.
struct DiffPaneView: View {
    let title:      String
    let subtitle:   String
    let lines:      [DiffLine]
    let scrollSync: ScrollSyncController
    let side:          FileSide
    var isJSON:        Bool = false
    var maxLineLength: Int = 0
    var badge:         String? = nil
    var showDropAffordance: Bool = false
    var onDropTap: (() -> Void)? = nil

    private var resolvedBadge: String {
        if let badge { return badge }
        return side == .left ? "ORIGINAL" : "WORKING COPY"
    }

    private var badgeColor: Color {
        side == .left ? DiffTheme.secondaryLabel : DiffTheme.workingCopyAccent
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header bar ──────────────────────────────────────────────
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(DiffTheme.iconTileBackground)
                        .frame(width: 34, height: 34)
                    Image(systemName: isJSON ? "curlybraces" : "doc.text")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DiffTheme.secondaryLabel)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(resolvedBadge)
                            .font(.system(size: 10, weight: .medium))
                            .tracking(0.25)
                            .foregroundStyle(badgeColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(DiffTheme.badgeBackground)
                            )
                    }

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(DiffTheme.tertiaryLabel)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer(minLength: 8)

                if showDropAffordance {
                    Button {
                        onDropTap?()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 11, weight: .medium))
                            Text("Drop file to compare")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(DiffTheme.secondaryLabel)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .strokeBorder(DiffTheme.separator, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Choose a file to compare")
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .background(DiffTheme.paneHeaderBackground)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(DiffTheme.separator)
                    .frame(height: 1)
            }
            .animation(.spring(duration: 0.28), value: isJSON)

            // ── Diff content ─────────────────────────────────────────────
            let currentOffset = scrollSync.offset

            DiffScrollView(
                lines:         lines,
                scrollSync:    scrollSync,
                syncOffset:    currentOffset,
                side:          side,
                maxLineLength: maxLineLength
            )
            .background(DiffTheme.canvasBackground)
        }
    }
}

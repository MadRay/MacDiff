import SwiftUI

struct TextInputModeView: View {
    @Bindable var viewModel: DiffViewModel

    var body: some View {
        VSplitView {
            // ── Input section (top) ──────────────────────────────────────
            HStack(spacing: 0) {
                TextInputPane(title: "Original",
                              text: $viewModel.leftText,
                              placeholder: "Paste or type original text here…")
                    .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(DiffTheme.separator)
                    .frame(width: 1)

                TextInputPane(title: "Modified",
                              text: $viewModel.rightText,
                              placeholder: "Paste or type modified text here…")
                    .frame(maxWidth: .infinity)
            }
            .frame(minHeight: 150, maxHeight: 320)

            // ── Diff result (bottom) ─────────────────────────────────────
            if viewModel.diffResult.hasContent {
                HStack(spacing: 0) {
                    DiffPaneView(
                        title:         "Original",
                        subtitle:      lineSubtitle(for: viewModel.diffResult.leftLines, isJSON: viewModel.leftIsJSON),
                        lines:         viewModel.diffResult.leftLines,
                        scrollSync:    viewModel.scrollSync,
                        side:          .left,
                        isJSON:        viewModel.leftIsJSON,
                        maxLineLength: viewModel.diffResult.maxLineLength,
                        badge:         "ORIGINAL"
                    )
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(DiffTheme.separator)
                        .frame(width: 1)

                    DiffPaneView(
                        title:         "Modified",
                        subtitle:      lineSubtitle(for: viewModel.diffResult.rightLines, isJSON: viewModel.rightIsJSON),
                        lines:         viewModel.diffResult.rightLines,
                        scrollSync:    viewModel.scrollSync,
                        side:          .right,
                        isJSON:        viewModel.rightIsJSON,
                        maxLineLength: viewModel.diffResult.maxLineLength,
                        badge:         "WORKING COPY"
                    )
                    .frame(maxWidth: .infinity)
                }
            } else {
                PlaceholderView(
                    icon:    "arrow.left.arrow.right.circle",
                    message: "Paste text in both panes above to see a live diff"
                )
            }
        }
    }

    private func lineSubtitle(for lines: [DiffLine], isJSON: Bool) -> String {
        let count = lines.filter { $0.kind != .empty }.count
        let base = "\(count) lines"
        return isJSON ? "\(base) · Normalized JSON" : base
    }
}

// MARK: - Text Input Pane

private struct TextInputPane: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DiffTheme.secondaryLabel)
                Spacer()
                if !text.isEmpty {
                    Button { text = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DiffTheme.paneHeaderBackground)

            Rectangle()
                .fill(DiffTheme.separator)
                .frame(height: 1)

            ZStack(alignment: .topLeading) {
                DiffTheme.canvasBackground
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.placeholder)
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
            }
        }
    }
}

// MARK: - Shared Placeholder

struct PlaceholderView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.quaternary)
            Text(message)
                .font(.callout)
                .foregroundStyle(DiffTheme.tertiaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DiffTheme.canvasBackground)
    }
}

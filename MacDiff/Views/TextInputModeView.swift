import SwiftUI

struct TextInputModeView: View {
    @Bindable var viewModel: DiffViewModel

    var body: some View {
        VSplitView {
            // ── Input section (top) ──────────────────────────────────────
            HSplitView {
                TextInputPane(title: "Original",
                              text: $viewModel.leftText,
                              placeholder: "Paste or type original text here…")
                TextInputPane(title: "Modified",
                              text: $viewModel.rightText,
                              placeholder: "Paste or type modified text here…")
            }
            .frame(minHeight: 150, maxHeight: 320)

            // ── Diff result (bottom) ─────────────────────────────────────
            if viewModel.diffResult.hasContent {
                HSplitView {
                    DiffPaneView(
                        title:      "Original",
                        subtitle:   "\(viewModel.diffResult.leftLines.filter  { $0.kind != .empty }.count) lines",
                        lines:      viewModel.diffResult.leftLines,
                        scrollSync: viewModel.scrollSync,
                        side:       .left
                    )
                    DiffPaneView(
                        title:      "Modified",
                        subtitle:   "\(viewModel.diffResult.rightLines.filter { $0.kind != .empty }.count) lines",
                        lines:      viewModel.diffResult.rightLines,
                        scrollSync: viewModel.scrollSync,
                        side:       .right
                    )
                }
            } else {
                PlaceholderView(
                    icon:    "arrow.left.arrow.right.circle",
                    message: "Paste text in both panes above to see a live diff"
                )
            }
        }
    }
}

// MARK: - Text Input Pane

private struct TextInputPane: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
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
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.bar)

            Divider()

            // Editable text area with placeholder
            ZStack(alignment: .topLeading) {
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
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

import SwiftUI

struct FileModeView: View {
    @Bindable var viewModel: DiffViewModel

    var body: some View {
        VStack(spacing: 0) {
            // ── File picker row ──────────────────────────────────────────
            HStack(spacing: 0) {
                DropZoneView(
                    side:         .left,
                    filePath:     viewModel.leftFilePath,
                    onFileLoaded: { url in viewModel.loadFile(side: .left,  url: url) },
                    onClear:      { viewModel.clearFile(side: .left) }
                )
                .frame(maxWidth: .infinity)

                Divider()

                DropZoneView(
                    side:         .right,
                    filePath:     viewModel.rightFilePath,
                    onFileLoaded: { url in viewModel.loadFile(side: .right, url: url) },
                    onClear:      { viewModel.clearFile(side: .right) }
                )
                .frame(maxWidth: .infinity)
            }
            .frame(height: 90)

            Divider()

            // ── Diff result ──────────────────────────────────────────────
            if viewModel.diffResult.hasContent {
                HStack(spacing: 0) {
                    DiffPaneView(
                        title:         "Original",
                        subtitle:      viewModel.leftFilePath,
                        lines:         viewModel.diffResult.leftLines,
                        scrollSync:    viewModel.scrollSync,
                        side:          .left,
                        isJSON:        viewModel.leftIsJSON,
                        maxLineLength: viewModel.diffResult.maxLineLength
                    )
                    .frame(maxWidth: .infinity)

                    Divider()

                    DiffPaneView(
                        title:         "Modified",
                        subtitle:      viewModel.rightFilePath,
                        lines:         viewModel.diffResult.rightLines,
                        scrollSync:    viewModel.scrollSync,
                        side:          .right,
                        isJSON:        viewModel.rightIsJSON,
                        maxLineLength: viewModel.diffResult.maxLineLength
                    )
                    .frame(maxWidth: .infinity)
                }
            } else {
                PlaceholderView(
                    icon:    "doc.on.doc.fill",
                    message: "Drop or select two files to compare them"
                )
            }
        }
    }
}

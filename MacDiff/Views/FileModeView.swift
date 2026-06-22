import SwiftUI

struct FileModeView: View {
    @Bindable var viewModel: DiffViewModel

    var body: some View {
        VSplitView {
            // ── File picker row ──────────────────────────────────────────
            HSplitView {
                DropZoneView(
                    side:         .left,
                    filePath:     viewModel.leftFilePath,
                    onFileLoaded: { url in viewModel.loadFile(side: .left,  url: url) },
                    onClear:      { viewModel.clearFile(side: .left) }
                )
                DropZoneView(
                    side:         .right,
                    filePath:     viewModel.rightFilePath,
                    onFileLoaded: { url in viewModel.loadFile(side: .right, url: url) },
                    onClear:      { viewModel.clearFile(side: .right) }
                )
            }
            .frame(minHeight: 88, maxHeight: 130)

            // ── Diff result ──────────────────────────────────────────────
            if viewModel.diffResult.hasContent {
                HSplitView {
                    DiffPaneView(
                        title:      "Original",
                        subtitle:   viewModel.leftFilePath,
                        lines:      viewModel.diffResult.leftLines,
                        scrollSync: viewModel.scrollSync,
                        side:       .left,
                        isJSON:     viewModel.leftIsJSON
                    )
                    DiffPaneView(
                        title:      "Modified",
                        subtitle:   viewModel.rightFilePath,
                        lines:      viewModel.diffResult.rightLines,
                        scrollSync: viewModel.scrollSync,
                        side:       .right,
                        isJSON:     viewModel.rightIsJSON
                    )
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

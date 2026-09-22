import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FileModeView: View {
    @Bindable var viewModel: DiffViewModel

    private var leftHasFile:  Bool { !viewModel.leftFilePath.isEmpty }
    private var rightHasFile: Bool { !viewModel.rightFilePath.isEmpty }
    private var bothFilesSelected: Bool { leftHasFile && rightHasFile }

    var body: some View {
        HStack(spacing: 0) {
            filePane(side: .left)
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(DiffTheme.separator)
                .frame(width: 1)

            filePane(side: .right)
                .frame(maxWidth: .infinity)
        }
        .background(DiffTheme.canvasBackground)
    }

    // MARK: - Per-side pane

    @ViewBuilder
    private func filePane(side: FileSide) -> some View {
        let hasFile = side == .left ? leftHasFile : rightHasFile

        if hasFile {
            // File selected — use the diff pane chrome (and drop-to-replace when both are loaded).
            DiffPaneView(
                title:         displayName(
                    side == .left ? viewModel.leftFilePath : viewModel.rightFilePath,
                    fallback: side == .left ? "Original" : "Modified"
                ),
                subtitle:      fileSubtitle(path: side == .left ? viewModel.leftFilePath : viewModel.rightFilePath, side: side),
                lines:         side == .left ? viewModel.diffResult.leftLines : viewModel.diffResult.rightLines,
                scrollSync:    viewModel.scrollSync,
                side:          side,
                isJSON:        side == .left ? viewModel.leftIsJSON : viewModel.rightIsJSON,
                maxLineLength: viewModel.diffResult.maxLineLength,
                badge:         side == .left ? "ORIGINAL" : "WORKING COPY",
                showDropAffordance: bothFilesSelected,
                onDropTap:     { openPanel(side: side) }
            )
            .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
                handleDrop(providers: providers, side: side)
            }
        } else {
            // No file yet — keep the large empty drop-zone style.
            DropZoneView(
                side:         side,
                filePath:     "",
                onFileLoaded: { url in viewModel.loadFile(side: side, url: url) },
                onClear:      { viewModel.clearFile(side: side) }
            )
        }
    }

    // MARK: - Helpers

    private func displayName(_ path: String, fallback: String) -> String {
        path.isEmpty ? fallback : (path as NSString).lastPathComponent
    }

    private func fileSubtitle(path: String, side: FileSide) -> String {
        let lines = side == .left
            ? viewModel.diffResult.leftLines
            : viewModel.diffResult.rightLines
        let count = lines.filter { $0.kind != .empty }.count
        let folder = ((path as NSString).deletingLastPathComponent as NSString).lastPathComponent
        let folderPart = folder.isEmpty ? path : folder
        let jsonPart = (side == .left ? viewModel.leftIsJSON : viewModel.rightIsJSON) ? " · JSON" : ""
        if count > 0 {
            return "\(folderPart) · \(count) lines\(jsonPart)"
        }
        return "\(folderPart)\(jsonPart)"
    }

    private func openPanel(side: FileSide) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.loadFile(side: side, url: url)
        }
    }

    private func handleDrop(providers: [NSItemProvider], side: FileSide) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            DispatchQueue.main.async {
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    viewModel.loadFile(side: side, url: url)
                } else if let url = item as? URL {
                    viewModel.loadFile(side: side, url: url)
                }
            }
        }
        return true
    }
}

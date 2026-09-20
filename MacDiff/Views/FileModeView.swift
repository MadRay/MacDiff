import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FileModeView: View {
    @Bindable var viewModel: DiffViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.diffResult.hasContent || hasAnyFile {
                HStack(spacing: 0) {
                    DiffPaneView(
                        title:         displayName(viewModel.leftFilePath, fallback: "Original"),
                        subtitle:      fileSubtitle(path: viewModel.leftFilePath, side: .left),
                        lines:         viewModel.diffResult.leftLines,
                        scrollSync:    viewModel.scrollSync,
                        side:          .left,
                        isJSON:        viewModel.leftIsJSON,
                        maxLineLength: viewModel.diffResult.maxLineLength,
                        badge:         "ORIGINAL",
                        showDropAffordance: viewModel.leftFilePath.isEmpty,
                        onDropTap:     { openPanel(side: .left) }
                    )
                    .frame(maxWidth: .infinity)
                    .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
                        handleDrop(providers: providers, side: .left)
                    }

                    Rectangle()
                        .fill(DiffTheme.separator)
                        .frame(width: 1)

                    DiffPaneView(
                        title:         displayName(viewModel.rightFilePath, fallback: "Modified"),
                        subtitle:      fileSubtitle(path: viewModel.rightFilePath, side: .right),
                        lines:         viewModel.diffResult.rightLines,
                        scrollSync:    viewModel.scrollSync,
                        side:          .right,
                        isJSON:        viewModel.rightIsJSON,
                        maxLineLength: viewModel.diffResult.maxLineLength,
                        badge:         "WORKING COPY",
                        showDropAffordance: true,
                        onDropTap:     { openPanel(side: .right) }
                    )
                    .frame(maxWidth: .infinity)
                    .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
                        handleDrop(providers: providers, side: .right)
                    }
                }
            } else {
                HStack(spacing: 0) {
                    DropZoneView(
                        side:         .left,
                        filePath:     viewModel.leftFilePath,
                        onFileLoaded: { url in viewModel.loadFile(side: .left,  url: url) },
                        onClear:      { viewModel.clearFile(side: .left) }
                    )
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(DiffTheme.separator)
                        .frame(width: 1)

                    DropZoneView(
                        side:         .right,
                        filePath:     viewModel.rightFilePath,
                        onFileLoaded: { url in viewModel.loadFile(side: .right, url: url) },
                        onClear:      { viewModel.clearFile(side: .right) }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .background(DiffTheme.canvasBackground)
    }

    private var hasAnyFile: Bool {
        !viewModel.leftFilePath.isEmpty || !viewModel.rightFilePath.isEmpty
    }

    private func displayName(_ path: String, fallback: String) -> String {
        path.isEmpty ? fallback : (path as NSString).lastPathComponent
    }

    private func fileSubtitle(path: String, side: FileSide) -> String {
        if path.isEmpty {
            return side == .left ? "Drop or choose a file" : "Drop file to compare"
        }
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

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct DropZoneView: View {
    let side:         FileSide
    let filePath:     String
    let onFileLoaded: (URL) -> Void
    let onClear:      () -> Void

    @State private var isTargeted = false

    private var hasFile: Bool { !filePath.isEmpty }
    private var accentColor: Color { side == .left
        ? Color(red: 0.93, green: 0.28, blue: 0.28)
        : Color(red: 0.12, green: 0.76, blue: 0.47) }

    var body: some View {
        Group {
            if hasFile {
                fileChip
            } else {
                dropTarget
            }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted, perform: handleDrop)
        .animation(.spring(duration: 0.22), value: hasFile)
        .animation(.easeInOut(duration: 0.12), value: isTargeted)
    }

    // MARK: - Drop target

    private var dropTarget: some View {
        VStack(spacing: 7) {
            Image(systemName: isTargeted ? "arrow.down.to.line.circle.fill" : "square.and.arrow.down")
                .font(.system(size: 28))
                .foregroundStyle(isTargeted ? accentColor : .secondary)
                .scaleEffect(isTargeted ? 1.15 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTargeted)

            Text(side == .left ? "Original File" : "Modified File")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 4) {
                Text("Drop here or")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("choose a file") { openPanel() }
                    .font(.caption)
                    .buttonStyle(.link)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isTargeted ? accentColor : Color.secondary.opacity(0.35),
                    style: StrokeStyle(
                        lineWidth: isTargeted ? 2 : 1.5,
                        dash: isTargeted ? [] : [9, 5]
                    )
                )
                .padding(10)
        )
        .background(isTargeted ? accentColor.opacity(0.05) : Color.clear)
    }

    // MARK: - File chip (after file is loaded)

    private var fileChip: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 22))
                .foregroundStyle(accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(side == .left ? "Original" : "Modified")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(filePath)
                    .font(.system(.callout, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button(action: onClear) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 17))
            }
            .buttonStyle(.plain)
            .help("Remove file")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(accentColor.opacity(0.07))
                .padding(10)
        )
    }

    // MARK: - Actions

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles         = true
        panel.canChooseDirectories   = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            onFileLoaded(url)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            DispatchQueue.main.async {
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    onFileLoaded(url)
                } else if let url = item as? URL {
                    onFileLoaded(url)
                }
            }
        }
        return true
    }
}

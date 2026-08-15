import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct DropZoneView: View {
    let side:         FileSide
    let filePath:     String
    let onFileLoaded: (URL) -> Void
    let onClear:      () -> Void

    @State private var isTargeted = false
    @State private var isHovered  = false

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
        Button(action: openPanel) {
            VStack(spacing: 5) {
                Image(systemName: isTargeted ? "arrow.down.to.line.circle.fill" : "square.and.arrow.down")
                    .font(.system(size: 24))
                    .foregroundStyle(isTargeted || isHovered ? accentColor : .secondary)
                    .scaleEffect(isTargeted ? 1.15 : (isHovered ? 1.05 : 1.0))
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isTargeted || isHovered)

                Text(side == .left ? "Original File" : "Modified File")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Text("Drop file here or click to choose")
                    .font(.caption)
                    .foregroundStyle(isHovered ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isTargeted ? accentColor : (isHovered ? accentColor.opacity(0.65) : Color.secondary.opacity(0.35)),
                        style: StrokeStyle(
                            lineWidth: isTargeted ? 2 : 1.5,
                            dash: isTargeted ? [] : [8, 4]
                        )
                    )
                    .padding(8)
            )
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isTargeted ? accentColor.opacity(0.08) : (isHovered ? accentColor.opacity(0.04) : Color.clear))
                    .padding(8)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
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

import SwiftUI

/// Compact Help panel listing app keyboard shortcuts.
struct HelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()
                .overlay(DiffTheme.separator)

            shortcutsSection
        }
        .frame(width: 360)
        .background(DiffTheme.canvasBackground)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "keyboard")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DiffTheme.secondaryLabel)

            Text("Keyboard Shortcuts")
                .font(.system(size: 15, weight: .semibold))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(DiffTheme.toolbarBackground)
    }

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Mode")

            VStack(spacing: 2) {
                ForEach(AppMode.allCases) { mode in
                    ShortcutRow(
                        title: mode.rawValue,
                        systemImage: mode.systemImage,
                        shortcut: mode.shortcutDisplay
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 18)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(DiffTheme.tertiaryLabel)
            .tracking(0.4)
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
    }
}

// MARK: - Row

private struct ShortcutRow: View {
    let title: String
    let systemImage: String
    let shortcut: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DiffTheme.secondaryLabel)
                .frame(width: 16)

            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Color.primary)

            Spacer(minLength: 8)

            Text(shortcut)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(DiffTheme.controlLabel)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(DiffTheme.controlFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .strokeBorder(DiffTheme.controlBorder, lineWidth: 1)
                        )
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

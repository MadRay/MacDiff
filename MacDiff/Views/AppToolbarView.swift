import SwiftUI

/// Custom Wonder-style toolbar — avoids macOS Liquid Glass toolbar capsules.
struct AppToolbarView: View {
    @Binding var selectedMode: AppMode
    let diffResult: DiffResult
    let isJSON: Bool
    let canSwap: Bool
    let onSwap: () -> Void
    let onClear: () -> Void

    /// Room for native traffic lights + a comfortable gap.
    private let trafficLightLeadingInset: CGFloat = 84
    /// Matches typical macOS traffic-light offset from the window top.
    private let contentTopInset: CGFloat = 10

    var body: some View {
        HStack(spacing: 12) {
            ModeSegmentedControl(selection: $selectedMode)

            ToolbarStatusPills(diffResult: diffResult, isJSON: isJSON)

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                ToolbarChromeButton(
                    title: "Swap Panes",
                    systemImage: "arrow.up.arrow.down",
                    isEnabled: canSwap,
                    action: onSwap
                )

                ToolbarIconButton(
                    systemImage: "trash",
                    help: "Clear All",
                    action: onClear
                )
            }
        }
        .padding(.leading, trafficLightLeadingInset)
        .padding(.trailing, 16)
        .padding(.top, contentTopInset)
        .frame(maxWidth: .infinity, minHeight: 52, maxHeight: 52, alignment: .top)
        .background(DiffTheme.toolbarBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DiffTheme.toolbarHairline)
                .frame(height: 1)
        }
    }
}

// MARK: - Mode segmented control

private struct ModeSegmentedControl: View {
    @Binding var selection: AppMode

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppMode.allCases) { mode in
                Button {
                    // Don't wrap in withAnimation — that made Text Input's VSplitView
                    // animate its layout differently from File Diff on tab switch.
                    selection = mode
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 12, weight: .semibold))
                        Text(mode.rawValue)
                            .font(.system(size: 13, weight: selection == mode ? .medium : .regular))
                    }
                    .foregroundStyle(selection == mode ? Color.primary : DiffTheme.secondaryLabel)
                    .padding(.horizontal, 12)
                    .frame(height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(selection == mode ? DiffTheme.segmentSelected : Color.clear)
                            .shadow(
                                color: selection == mode ? Color.black.opacity(0.08) : .clear,
                                radius: 1, y: 0.5
                            )
                            .animation(.easeInOut(duration: 0.15), value: selection)
                    )
                }
                .buttonStyle(.plain)
                .help("\(mode.rawValue) (\(mode.shortcutDisplay))")
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(DiffTheme.segmentTrack)
        )
    }
}

// MARK: - Chrome buttons

private struct ToolbarChromeButton: View {
    let title: String
    let systemImage: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13))
            }
            .foregroundStyle(isEnabled ? Color.primary : DiffTheme.secondaryLabel.opacity(0.5))
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(DiffTheme.controlFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(DiffTheme.controlBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 1, y: 0.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .help(title)
    }
}

private struct ToolbarIconButton: View {
    let systemImage: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DiffTheme.secondaryLabel)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(DiffTheme.controlFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(DiffTheme.controlBorder, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 1, y: 0.5)
                )
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var viewModel = DiffViewModel()

    private var isJSONActive: Bool {
        viewModel.leftIsJSON || viewModel.rightIsJSON
    }

    private var canSwap: Bool {
        viewModel.diffResult.hasContent
            || !viewModel.leftText.isEmpty
            || !viewModel.rightText.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            AppToolbarView(
                selectedMode: $viewModel.selectedMode,
                diffResult: viewModel.diffResult,
                isJSON: isJSONActive,
                canSwap: canSwap,
                onSwap: { viewModel.swapPanes() },
                onClear: { viewModel.clearAll() }
            )

            ZStack {
                TextInputModeView(viewModel: viewModel)
                    .opacity(viewModel.selectedMode == .text ? 1 : 0)
                    .allowsHitTesting(viewModel.selectedMode == .text)

                FileModeView(viewModel: viewModel)
                    .opacity(viewModel.selectedMode == .file ? 1 : 0)
                    .allowsHitTesting(viewModel.selectedMode == .file)
            }
            // Same crossfade for both modes — avoids VSplitView's insert layout animation.

            FooterStatsBar(
                diffResult: viewModel.diffResult,
                isJSON: isJSONActive
            )
        }
        .ignoresSafeArea(.container, edges: .top)
        .background(DiffTheme.canvasBackground.ignoresSafeArea())
        .frame(minWidth: 960, minHeight: 600)
        .background(WindowChromeBridge())
        .focusedSceneValue(\.selectedAppMode, $viewModel.selectedMode)
    }
}

// MARK: - Focused mode binding (for ⌘1 / ⌘2 menu commands)

struct SelectedAppModeKey: FocusedValueKey {
    typealias Value = Binding<AppMode>
}

extension FocusedValues {
    var selectedAppMode: Binding<AppMode>? {
        get { self[SelectedAppModeKey.self] }
        set { self[SelectedAppModeKey.self] = newValue }
    }
}

// MARK: - Window chrome

/// Transparent titlebar so traffic lights overlay our custom toolbar row.
private struct WindowChromeBridge: NSViewRepresentable {
    func makeNSView(context: Context) -> ChromeView { ChromeView() }

    func updateNSView(_ nsView: ChromeView, context: Context) {
        nsView.applyChrome()
    }

    final class ChromeView: NSView {
        private static let toolbarHeight: CGFloat = 52

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyChrome()
        }

        override func layout() {
            super.layout()
            alignTrafficLights()
        }

        func applyChrome() {
            guard let window else { return }
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.titlebarSeparatorStyle = .none
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.toolbar = nil
            alignTrafficLights()
        }

        /// Keep traffic lights vertically centered in our 52pt toolbar row.
        private func alignTrafficLights() {
            guard let window,
                  let close = window.standardWindowButton(.closeButton),
                  let container = close.superview
            else { return }

            let buttonHeight = close.frame.height
            // Titlebar coordinates are bottom-origin; pin lights to the vertical
            // center of the top toolbarHeight band.
            let y = container.bounds.height - Self.toolbarHeight / 2 - buttonHeight / 2

            for type: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
                guard let button = window.standardWindowButton(type) else { continue }
                var frame = button.frame
                frame.origin.y = y.rounded()
                button.frame = frame
            }
        }
    }
}

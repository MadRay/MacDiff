import SwiftUI
import AppKit

struct ContentView: View {
    @State private var viewModel = DiffViewModel()
    @State private var trafficLightInset: CGFloat = 78

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
                leadingInset: trafficLightInset,
                onSwap: { viewModel.swapPanes() },
                onClear: { viewModel.clearAll() }
            )

            Group {
                switch viewModel.selectedMode {
                case .text: TextInputModeView(viewModel: viewModel)
                case .file: FileModeView(viewModel: viewModel)
                }
            }
            .animation(.easeInOut(duration: 0.18), value: viewModel.selectedMode)

            FooterStatsBar(
                diffResult: viewModel.diffResult,
                isJSON: isJSONActive
            )
        }
        // Draw under the system titlebar so traffic lights sit in our toolbar row.
        .ignoresSafeArea(.container, edges: .top)
        .background(DiffTheme.canvasBackground.ignoresSafeArea())
        .frame(minWidth: 960, minHeight: 600)
        .background(
            WindowChromeBridge(trafficLightInset: $trafficLightInset)
        )
    }
}

// MARK: - Window chrome

/// Configures a transparent full-size titlebar and reports traffic-light width.
private struct WindowChromeBridge: NSViewRepresentable {
    @Binding var trafficLightInset: CGFloat

    func makeNSView(context: Context) -> ChromeView {
        let view = ChromeView()
        view.onInsetChange = { inset in
            DispatchQueue.main.async {
                if abs(trafficLightInset - inset) > 0.5 {
                    trafficLightInset = inset
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: ChromeView, context: Context) {
        nsView.onInsetChange = { inset in
            DispatchQueue.main.async {
                if abs(trafficLightInset - inset) > 0.5 {
                    trafficLightInset = inset
                }
            }
        }
        nsView.applyChrome()
    }

    final class ChromeView: NSView {
        var onInsetChange: ((CGFloat) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyChrome()
        }

        override func layout() {
            super.layout()
            reportTrafficLightInset()
        }

        func applyChrome() {
            guard let window else { return }

            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.titlebarSeparatorStyle = .none
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.toolbar = nil

            // Keep traffic lights visible and vertically centered in our toolbar.
            for type: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
                window.standardWindowButton(type)?.isHidden = false
            }

            reportTrafficLightInset()
        }

        private func reportTrafficLightInset() {
            guard let window,
                  let close = window.standardWindowButton(.closeButton),
                  let zoom = window.standardWindowButton(.zoomButton),
                  let titlebar = close.superview
            else {
                onInsetChange?(78)
                return
            }

            // Convert zoom button's trailing edge into window content coordinates,
            // then add a small gap before our segmented control.
            let zoomFrame = zoom.convert(zoom.bounds, to: nil)
            let inset = zoomFrame.maxX + 14
            onInsetChange?(max(70, inset))

            // Nudge traffic lights to vertically center in a ~52pt toolbar row.
            let toolbarHeight: CGFloat = 52
            let buttonHeight = close.bounds.height
            let y = ((toolbarHeight - buttonHeight) / 2).rounded()
            for type: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
                guard let button = window.standardWindowButton(type) else { continue }
                var frame = button.frame
                frame.origin.y = y
                button.frame = frame
            }

            _ = titlebar
        }
    }
}

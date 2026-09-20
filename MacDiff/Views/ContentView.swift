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
        .ignoresSafeArea(.container, edges: .top)
        .background(DiffTheme.canvasBackground.ignoresSafeArea())
        .frame(minWidth: 960, minHeight: 600)
        .background(WindowChromeBridge())
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
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyChrome()
        }

        func applyChrome() {
            guard let window else { return }
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.titlebarSeparatorStyle = .none
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.toolbar = nil
        }
    }
}

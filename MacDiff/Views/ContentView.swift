import SwiftUI
import AppKit

struct ContentView: View {
    @State private var viewModel = DiffViewModel()
    @State private var chrome = TitlebarChrome.fallback

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
                chrome: chrome,
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
        .background(WindowChromeBridge(chrome: $chrome))
    }
}

// MARK: - Titlebar metrics

struct TitlebarChrome: Equatable {
    /// Distance from leading window edge to first toolbar control.
    var leadingInset: CGFloat
    /// Total toolbar / titlebar height.
    var height: CGFloat
    /// Top padding so controls share a baseline with traffic lights.
    var controlsTopInset: CGFloat

    static let fallback = TitlebarChrome(leadingInset: 86, height: 52, controlsTopInset: 11)
}

// MARK: - Window chrome bridge

private struct WindowChromeBridge: NSViewRepresentable {
    @Binding var chrome: TitlebarChrome

    func makeNSView(context: Context) -> ChromeView {
        let view = ChromeView()
        view.onChange = { next in
            DispatchQueue.main.async {
                if chrome != next { chrome = next }
            }
        }
        return view
    }

    func updateNSView(_ nsView: ChromeView, context: Context) {
        nsView.onChange = { next in
            DispatchQueue.main.async {
                if chrome != next { chrome = next }
            }
        }
        nsView.applyChrome()
    }

    final class ChromeView: NSView {
        var onChange: ((TitlebarChrome) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyChrome()
        }

        override func layout() {
            super.layout()
            publishMetrics()
        }

        func applyChrome() {
            guard let window else { return }
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.titlebarSeparatorStyle = .none
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.toolbar = nil
            publishMetrics()
        }

        private func publishMetrics() {
            guard let window,
                  let contentView = window.contentView,
                  let close = window.standardWindowButton(.closeButton),
                  let zoom = window.standardWindowButton(.zoomButton)
            else {
                onChange?(.fallback)
                return
            }

            // Traffic-light frames in the content view's coordinate space.
            let closeRect = close.superview?.convert(close.frame, to: contentView) ?? close.frame
            let zoomRect  = zoom.superview?.convert(zoom.frame, to: contentView) ?? zoom.frame

            // Content is top-left origin in SwiftUI; AppKit contentView is bottom-left.
            // Convert to top-down metrics for the SwiftUI toolbar.
            let contentHeight = contentView.bounds.height
            let lightsTop = contentHeight - closeRect.maxY
            let lightsBottom = contentHeight - closeRect.minY
            let lightsHeight = lightsBottom - lightsTop

            // Titlebar tall enough for lights + comfortable vertical padding.
            let verticalPadding: CGFloat = 10
            let height = max(52, (lightsHeight + verticalPadding * 2).rounded())

            // Center controls on the same midY as the traffic lights.
            let lightsMidYFromTop = lightsTop + lightsHeight / 2
            let controlRowHeight: CGFloat = 30
            let controlsTopInset = max(8, (lightsMidYFromTop - controlRowHeight / 2).rounded())

            // Generous gap after the green light before our segmented control.
            let leadingInset = (zoomRect.maxX + 22).rounded()

            onChange?(TitlebarChrome(
                leadingInset: max(80, leadingInset),
                height: height,
                controlsTopInset: controlsTopInset
            ))
        }
    }
}

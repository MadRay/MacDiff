import SwiftUI

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
        .background(DiffTheme.canvasBackground)
        .frame(minWidth: 960, minHeight: 600)
    }
}

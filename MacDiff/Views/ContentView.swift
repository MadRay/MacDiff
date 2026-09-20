import SwiftUI

struct ContentView: View {
    @State private var viewModel = DiffViewModel()

    private var isJSONActive: Bool {
        viewModel.leftIsJSON || viewModel.rightIsJSON
    }

    var body: some View {
        VStack(spacing: 0) {
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
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Picker("Mode", selection: $viewModel.selectedMode) {
                    ForEach(AppMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
                .labelsHidden()
                .help("Switch between text input and file diff")
            }

            ToolbarItem(placement: .principal) {
                ToolbarStatusPills(
                    diffResult: viewModel.diffResult,
                    isJSON: isJSONActive
                )
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.swapPanes()
                } label: {
                    Label("Swap Panes", systemImage: "arrow.left.arrow.right")
                }
                .help("Swap left and right panes")
                .disabled(!viewModel.diffResult.hasContent
                          && viewModel.leftText.isEmpty
                          && viewModel.rightText.isEmpty)

                Button {
                    viewModel.clearAll()
                } label: {
                    Label("Clear All", systemImage: "trash")
                }
                .help("Clear both panes and reset the diff")
            }
        }
        .navigationTitle("MacDiff")
    }
}

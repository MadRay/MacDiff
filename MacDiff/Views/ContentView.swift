import SwiftUI

struct ContentView: View {
    @State private var viewModel = DiffViewModel()

    var body: some View {
        VStack(spacing: 0) {
            SummaryBannerView(diffResult: viewModel.diffResult)
            Divider()
            Group {
                switch viewModel.selectedMode {
                case .text: TextInputModeView(viewModel: viewModel)
                case .file: FileModeView(viewModel: viewModel)
                }
            }
            .animation(.easeInOut(duration: 0.18), value: viewModel.selectedMode)
        }
        .frame(minWidth: 900, minHeight: 560)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Mode", selection: $viewModel.selectedMode) {
                    ForEach(AppMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 230)
                .labelsHidden()
            }
            ToolbarItem(placement: .automatic) {
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

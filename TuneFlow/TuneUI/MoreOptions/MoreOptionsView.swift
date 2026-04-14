import SwiftUI

struct MoreOptionsView: View {
    static let compactSheetHeight: CGFloat = 192

    @State private var viewModel: MoreOptionsViewModel

    init(viewModel: MoreOptionsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            songHeader
            actionRows
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
        .presentationDetents([.height(MoreOptionsView.compactSheetHeight)])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews

    private var songHeader: some View {
        VStack(spacing: 4) {
            Text(viewModel.songTitle)
                // Note: headline is 17, mockup asks for 18
                .font(.headline)
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
            Text(viewModel.artistName)
                // Note: footnote is 13, mockup asks for 14
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 24)
    }

    private var actionRows: some View {
        Button(action: viewModel.viewAlbum) {
            HStack(spacing: 16) {
                Image(.albumIcon)
                    .frame(width: 24, height: 24)

                Text("View album")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color.white)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .padding(.horizontal, 32)
            .frame(height: 50)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canViewAlbum)
        .opacity(viewModel.canViewAlbum ? 1 : 0.5)
    }
}

// MARK: - Preview

#Preview {
    Color.clear
           .sheet(isPresented: .constant(true)) {
               MoreOptionsView(viewModel: MoreOptionsViewModel(song: .previewFixture, router: AppRouter()))
           }
}

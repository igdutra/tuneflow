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
        .frame(maxWidth: .infinity, alignment: .top)
        // TODO: Investigate padding on this sheet
        // TODO: Maybe instead of hardcoded height do .fraction(0.25)
        .presentationDetents([.height(MoreOptionsView.compactSheetHeight)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(12)
        .presentationBackground(Color(hex: "262626").opacity(0.8))
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
            .padding(.horizontal, 32)
            .frame(height: 50)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    Color.clear
           .sheet(isPresented: .constant(true)) {
               MoreOptionsView(viewModel: MoreOptionsViewModel(song: .previewFixture, router: AppRouter()))
           }
}

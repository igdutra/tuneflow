import SwiftUI

struct MoreOptionsView: View {
    static let compactSheetHeight: CGFloat = 192

    @State private var viewModel: MoreOptionsViewModel

    init(viewModel: MoreOptionsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            dragHandle
            songHeader
            actionRows
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(MoreOptionsView.compactSheetHeight)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(12)
        .presentationBackground(Color(hex: "2C2C2E"))
    }

    // MARK: - Subviews

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(hex: "3A3A3C"))
            .frame(width: 32, height: 4)
            .padding(.top, 8)
            .padding(.bottom, 16)
    }

    private var songHeader: some View {
        VStack(spacing: 4) {
            Text(viewModel.songTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
            Text(viewModel.artistName)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    private var actionRows: some View {
        Button(action: viewModel.viewAlbum) {
            HStack(spacing: 16) {
                Image(systemName: "music.note")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.white)
                    .frame(width: 20)
                Text("View album")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
        }
        .buttonStyle(.plain)
    }
}

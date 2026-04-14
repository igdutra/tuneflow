import SwiftUI
import TuneDomain

struct AlbumView: View {
    @State private var viewModel: AlbumViewModel

    init(viewModel: AlbumViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AlbumHeroView(
                    artworkURL: viewModel.artworkURL,
                    title: viewModel.title,
                    artistName: viewModel.artistName
                )

                AlbumTrackListView(tracks: viewModel.tracks)
            }
        }
        .background(Color.black)
        .scrollContentBackground(.hidden)
        .stateOverlay(
            state: viewModel.state,
            errorTitle: "Load Failed",
            errorMessage: "Unable to load album. Check your connection and try again.",
            errorAction: .init(title: "Retry") { Task { await viewModel.load() } }
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load() }
    }
}

// MARK: - Hero Section

private struct AlbumHeroView: View {
    let artworkURL: URL?
    let title: String
    let artistName: String

    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: artworkURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(artistName)
                // Note: footnote is 13, mockup asks for 14
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 32)
    }
}

// MARK: - Track List

private struct AlbumTrackListView: View {
    let tracks: [Song]

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(tracks) { track in
                AlbumTrackRowView(track: track)
            }
        }
    }
}

private struct AlbumTrackRowView: View {
    let track: Song

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: track.artworkURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 2) {
                Text(track.trackName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(track.artistName)
                    // Note: footnote is 13, mockup asks for 14
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color(hex: "#737373"))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}


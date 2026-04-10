import SwiftUI
import TuneDomain

struct SongsView: View {
    @State private var viewModel: SongsViewModel

    init(viewModel: SongsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.songs) { song in
                    SongRowView(
                        artworkURL: song.artworkURL,
                        title: song.trackName,
                        artist: song.artistName,
                        onMoreTapped: { /* TODO: Track 6 — Bottom Sheet */ }
                    )
                    .onAppear {
                        if song.id == viewModel.songs.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.black)
            // TODO: loading overlay — show ProgressView when viewModel.state.isLoading
            // TODO: error overlay — show retry UI when viewModel.state.error != nil
            // TODO: empty overlay — show ContentUnavailableView when songs are empty after search
            .navigationTitle("Songs")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .searchable(text: $viewModel.searchText, prompt: "Search")
        .onSubmit(of: .search) {
            Task { await viewModel.search() }
        }
    }
}

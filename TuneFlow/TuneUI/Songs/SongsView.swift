import SwiftUI
import TuneDomain

struct SongsView: View {
    @State private var viewModel: SongsViewModel
    @State private var isSearchPresented = false
    @State private var showsCollapsedSearchButton = false

    init(viewModel: SongsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            if viewModel.hasRecentSongs && viewModel.searchText.isEmpty && !isSearchPresented {
                Section("Recently Played") {
                    ForEach(viewModel.recentSongs) { song in
                        SongRowView(
                            artworkURL: song.artworkURL,
                            title: song.trackName,
                            artist: song.artistName,
                            onMoreTapped: { viewModel.showMoreOptions(for: song) }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectSong(song)
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }

            ForEach(viewModel.songs) { song in
                SongRowView(
                    artworkURL: song.artworkURL,
                    title: song.trackName,
                    artist: song.artistName,
                    onMoreTapped: { viewModel.showMoreOptions(for: song) }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectSong(song)
                }
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
        .onAppear {
            Task { await viewModel.loadRecentlyPlayed() }
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y > 20
        } action: { _, isCollapsed in
            withAnimation(.easeInOut(duration: 0.2)) {
                showsCollapsedSearchButton = isCollapsed && !isSearchPresented
            }
        }
        .overlay {
            if viewModel.songs.isEmpty, !viewModel.searchText.isEmpty, viewModel.state.isLoaded {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .stateOverlay(
            state: viewModel.state,
            errorAction: .init(title: "Retry") { Task { await viewModel.search() } }
        )
        .navigationTitle("Songs")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        // TODO: JIRA-xxxx Verify toolbar + .searchable behavior. ACs are met but experience and code might not me optimal. Needs verification.
        // Note: if needed, search can be transformed to a custom component
        // to match the design more closely. Going with native for the moment.
        .searchable(
            text: $viewModel.searchText,
            isPresented: $isSearchPresented,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search"
        )
        .searchToolbarBehavior(.automatic)
        .onChange(of: isSearchPresented) { _, isPresented in
            if isPresented {
                showsCollapsedSearchButton = false
            } else {
                viewModel.clearSearch()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if showsCollapsedSearchButton {
                    Button {
                        isSearchPresented = true
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                }
            }
        }
        .onSubmit(of: .search) {
            Task { await viewModel.search() }
        }
    }
}

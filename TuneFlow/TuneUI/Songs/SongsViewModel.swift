import Foundation
import TuneDomain

@MainActor
@Observable
final class SongsViewModel {
    private let repository: SongRepository
    private let recentlyPlayedRepository: any RecentlyPlayedRepository
    private let router: AppRouter

    private(set) var state: ViewState = .idle
    private(set) var songs: [Song] = []
    private(set) var recentSongs: [Song] = []
    var searchText = ""

    @ObservationIgnored private var currentOffset = 0
    @ObservationIgnored private let pageSize = 25
    @ObservationIgnored private var hasReachedEnd = false

    var hasResults: Bool { !songs.isEmpty }
    var hasRecentSongs: Bool { !recentSongs.isEmpty }

    init(
        repository: SongRepository,
        recentlyPlayedRepository: any RecentlyPlayedRepository,
        router: AppRouter
    ) {
        self.repository = repository
        self.recentlyPlayedRepository = recentlyPlayedRepository
        self.router = router
    }

    func selectSong(_ song: Song) {
        let index = songs.firstIndex(of: song) ?? 0
        router.push(.player(song, queue: songs, currentIndex: index))
    }

    func showMoreOptions(for song: Song) {
        router.present(.moreOptions(song))
    }

    func clearSearch() {
        songs = []
        state = .idle
    }

    func search() async {
        guard !searchText.isEmpty else {
            songs = []
            state = .idle
            return
        }
        state = .loading
        currentOffset = 0
        hasReachedEnd = false
        do {
            let result = try await repository.search(
                query: searchText,
                limit: pageSize,
                offset: 0
            )
            songs = result
            currentOffset = result.count
            hasReachedEnd = result.count < pageSize
            state = .loaded
        } catch {
            state = .error(error)
        }
    }

    func loadMore() async {
        guard !hasReachedEnd, !state.isLoading else { return }
        do {
            let result = try await repository.search(
                query: searchText,
                limit: pageSize,
                offset: currentOffset
            )
            songs.append(contentsOf: result)
            currentOffset += result.count
            hasReachedEnd = result.count < pageSize
        } catch {
            // Pagination failure preserves the existing list — silently ignored for now
        }
    }

    func loadRecentlyPlayed() async {
        do {
            recentSongs = try await recentlyPlayedRepository.loadRecent(limit: 10)
        } catch {
            recentSongs = []
        }
    }
}

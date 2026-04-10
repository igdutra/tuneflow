import Foundation
import TuneDomain

@MainActor
@Observable
final class SongsViewModel {
    private let repository: SongRepository
    private let router: AppRouter

    private(set) var state: ViewState = .idle
    private(set) var songs: [Song] = []
    var searchText = ""

    @ObservationIgnored private var currentOffset = 0
    @ObservationIgnored private let pageSize = 10
    @ObservationIgnored private var hasReachedEnd = false

    var hasResults: Bool { !songs.isEmpty }

    init(repository: SongRepository, router: AppRouter) {
        self.repository = repository
        self.router = router
    }

    func selectSong(_ song: Song) {
        router.push(.player(song))
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
}

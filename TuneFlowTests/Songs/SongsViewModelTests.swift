import Foundation
import Testing
import TuneDomain
@testable import TuneFlow

@MainActor
struct SongsViewModelTests {

    // MARK: - Initial State

    @Test func init_startsWithIdleStateAndEmptySongs() {
        let (sut, _, _) = makeSUT()

        #expect(sut.state.isIdle)
        #expect(sut.songs.isEmpty)
        #expect(sut.searchText.isEmpty)
    }

    // MARK: - Search Success

    @Test func search_onSuccess_populatesSongsAndTransitionsToLoaded() async {
        let (sut, spy, _) = makeSUT()
        spy.stub(result: Song.fixtures(count: 5))
        sut.searchText = "Prince"

        await sut.search()

        #expect(sut.state.isLoaded)
        #expect(sut.songs.count == 5)
    }

    @Test func search_onSuccess_callsRepositoryWithCorrectParameters() async {
        let (sut, spy, _) = makeSUT()
        spy.stub(result: [])
        sut.searchText = "Beatles"

        await sut.search()

        #expect(spy.searchCallCount == 1)
        #expect(spy.searchCalledWithQuery == "Beatles")
        #expect(spy.searchCalledWithLimit == 10)
        #expect(spy.searchCalledWithOffset == 0)
    }

    // MARK: - Search Failure

    @Test func search_onFailure_transitionsToErrorAndKeepsSongsEmpty() async {
        let (sut, spy, _) = makeSUT()
        spy.stub(error: anyError())
        sut.searchText = "Prince"

        await sut.search()

        #expect(sut.state.hasError == true)
        #expect(sut.songs.isEmpty)
    }

    // MARK: - Empty Search Text

    @Test func search_withEmptyText_clearsSongsAndResetsToIdle() async {
        let (sut, spy, _) = makeSUT()
        spy.stub(result: Song.fixtures(count: 3))
        sut.searchText = "Prince"
        await sut.search()

        sut.searchText = ""
        await sut.search()

        #expect(sut.state.isIdle)
        #expect(sut.songs.isEmpty)
        #expect(spy.searchCallCount == 1)
    }

    // MARK: - New Search Replaces Results

    @Test func search_onNewSearch_replacesExistingResults() async {
        let (sut, spy, _) = makeSUT()
        spy.stub(result: Song.fixtures(count: 5))
        sut.searchText = "Prince"
        await sut.search()

        spy.stub(result: Song.fixtures(count: 3, startingId: 100))
        sut.searchText = "Beatles"
        await sut.search()

        #expect(sut.songs.count == 3)
        #expect(spy.searchCallCount == 2)
    }

    @Test func search_resetsOffsetToZeroOnNewSearch() async {
        let (sut, spy, _) = makeSUT()
        spy.stub(result: Song.fixtures(count: 10))
        sut.searchText = "Prince"
        await sut.search()
        await sut.loadMore()

        spy.stub(result: Song.fixtures(count: 3, startingId: 100))
        sut.searchText = "Beatles"
        await sut.search()

        #expect(spy.searchCalledWithOffset == 0)
    }

    // MARK: - Pagination

    @Test func loadMore_appendsNextPage() async {
        let (sut, spy, _) = makeSUT()
        spy.stub(result: Song.fixtures(count: 10))
        sut.searchText = "Prince"
        await sut.search()

        spy.stub(result: Song.fixtures(count: 5, startingId: 11))
        await sut.loadMore()

        #expect(sut.songs.count == 15)
        #expect(spy.searchCallCount == 2)
        #expect(spy.searchCalledWithOffset == 10)
    }

    @Test func loadMore_whenReachedEnd_doesNotCallRepository() async {
        let (sut, spy, _) = makeSUT()
        spy.stub(result: Song.fixtures(count: 7))  // fewer than pageSize(10) → end reached
        sut.searchText = "Prince"
        await sut.search()

        await sut.loadMore()

        #expect(spy.searchCallCount == 1)
    }

    @Test func loadMore_onFailure_preservesExistingSongs() async {
        let (sut, spy, _) = makeSUT()
        spy.stub(result: Song.fixtures(count: 10))
        sut.searchText = "Prince"
        await sut.search()

        spy.stub(error: anyError())
        await sut.loadMore()

        #expect(sut.songs.count == 10)
        #expect(sut.state.isLoaded)
    }

    // MARK: - hasResults

    @Test func hasResults_returnsFalseWhenSongsAreEmpty() {
        let (sut, _, _) = makeSUT()

        #expect(sut.hasResults == false)
    }

    @Test func hasResults_returnsTrueAfterSuccessfulSearch() async {
        let (sut, spy, _) = makeSUT()
        spy.stub(result: Song.fixtures(count: 3))
        sut.searchText = "Prince"

        await sut.search()

        #expect(sut.hasResults == true)
    }

    // MARK: - loadRecentlyPlayed

    @Test func loadRecentlyPlayed_onSuccess_populatesRecentSongs() async {
        let (sut, _, repoSpy) = makeSUT()
        repoSpy.stub(result: Song.fixtures(count: 3))

        await sut.loadRecentlyPlayed()

        #expect(sut.recentSongs.count == 3)
    }

    @Test func loadRecentlyPlayed_onFailure_setsRecentSongsToEmpty() async {
        let (sut, _, repoSpy) = makeSUT()
        repoSpy.stub(error: anyError())

        await sut.loadRecentlyPlayed()

        #expect(sut.recentSongs.isEmpty)
    }

    @Test func hasRecentSongs_returnsFalseWhenEmpty() {
        let (sut, _, _) = makeSUT()

        #expect(sut.hasRecentSongs == false)
    }

    @Test func hasRecentSongs_returnsTrueAfterLoad() async {
        let (sut, _, repoSpy) = makeSUT()
        repoSpy.stub(result: Song.fixtures(count: 2))

        await sut.loadRecentlyPlayed()

        #expect(sut.hasRecentSongs == true)
    }
}

// MARK: - Helpers

private extension SongsViewModelTests {
    typealias SUTBundle = (sut: SongsViewModel, spy: SongRepositorySpy, repoSpy: RecentlyPlayedRepositorySpy)

    func makeSUT(source: SourceLocation = #_sourceLocation) -> SUTBundle {
        let spy = SongRepositorySpy()
        let repoSpy = RecentlyPlayedRepositorySpy()
        let sut = SongsViewModel(
            repository: spy,
            recentlyPlayedRepository: repoSpy,
            router: AppRouter()
        )
        _ = source
        return (sut, spy, repoSpy)
    }

    func anyError() -> Error {
        NSError(domain: "test", code: 0)
    }
}

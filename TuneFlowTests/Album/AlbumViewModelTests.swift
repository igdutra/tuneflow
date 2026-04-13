import Testing
import Foundation
import TuneDomain
@testable import TuneFlow

@MainActor
struct AlbumViewModelTests {

    // MARK: - Initial State

    @Test func init_startsWithIdleStateAndNilAlbum() {
        let (sut, _) = makeSUT()

        #expect(sut.state == .idle)
        #expect(sut.album == nil)
    }

    // MARK: - load()

    @Test func load_onSuccess_transitionsToLoadedState() async {
        let (sut, spy) = makeSUT()
        spy.stubAlbum(result: .fixture())

        await sut.load()

        #expect(sut.state == .loaded)
    }

    @Test func load_onSuccess_populatesAlbum() async {
        let expectedAlbum = Album.fixture(id: 42, title: "Discovery", artistName: "Daft Punk")
        let (sut, spy) = makeSUT()
        spy.stubAlbum(result: expectedAlbum)

        await sut.load()

        #expect(sut.album == expectedAlbum)
    }

    @Test func load_onFailure_transitionsToErrorState() async {
        let (sut, spy) = makeSUT()
        spy.stubAlbum(error: anyError())

        await sut.load()

        #expect(sut.state.hasError == true)
    }

    @Test func load_onFailure_albumRemainsNil() async {
        let (sut, spy) = makeSUT()
        spy.stubAlbum(error: anyError())

        await sut.load()

        #expect(sut.album == nil)
    }

    @Test func load_passesCorrectCollectionIdToRepository() async {
        let (sut, spy) = makeSUT(collectionId: 99)
        spy.stubAlbum(result: .fixture())

        await sut.load()

        #expect(spy.fetchAlbumCalledWithCollectionId == 99)
    }

    // MARK: - Computed Display Properties

    @Test func title_afterLoad_returnAlbumTitle() async {
        let (sut, spy) = makeSUT()
        spy.stubAlbum(result: .fixture(title: "Homework"))

        await sut.load()

        #expect(sut.title == "Homework")
    }

    @Test func artistName_afterLoad_returnsAlbumArtistName() async {
        let (sut, spy) = makeSUT()
        spy.stubAlbum(result: .fixture(artistName: "Daft Punk"))

        await sut.load()

        #expect(sut.artistName == "Daft Punk")
    }

    @Test func tracks_afterLoad_returnsAlbumTracks() async {
        let expectedTracks = Song.fixtures(count: 3)
        let (sut, spy) = makeSUT()
        spy.stubAlbum(result: .fixture(tracks: expectedTracks))

        await sut.load()

        #expect(sut.tracks == expectedTracks)
    }

    @Test func title_beforeLoad_returnsEmptyString() {
        let (sut, _) = makeSUT()

        #expect(sut.title == "")
    }

    @Test func tracks_beforeLoad_returnsEmptyArray() {
        let (sut, _) = makeSUT()

        #expect(sut.tracks.isEmpty)
    }
}

// MARK: - Helpers

private extension AlbumViewModelTests {
    typealias SUTBundle = (sut: AlbumViewModel, spy: SongRepositorySpy)

    func makeSUT(
        collectionId: Int = 1,
        source: SourceLocation = #_sourceLocation
    ) -> SUTBundle {
        let spy = SongRepositorySpy()
        let router = AppRouter()
        let sut = AlbumViewModel(collectionId: collectionId, repository: spy, router: router)
        _ = source
        return (sut, spy)
    }

    func anyError() -> Error {
        NSError(domain: "test", code: 0)
    }
}

import Foundation
import Testing
import TuneDomain
@testable import TuneFlow

@MainActor
struct MoreOptionsViewModelTests {

    // MARK: - Display Properties

    @Test func init_exposesCorrectSongTitle() {
        let (sut, song, _) = makeSUT(song: .fixture(trackName: "Purple Rain"))

        #expect(sut.songTitle == song.trackName)
    }

    @Test func init_exposesCorrectArtistName() {
        let (sut, song, _) = makeSUT(song: .fixture(artistName: "Prince"))

        #expect(sut.artistName == song.artistName)
    }

    // MARK: - viewAlbum

    @Test func viewAlbum_pushesAlbumRouteWithSongCollectionId() {
        let song = Song.fixture(collectionId: 42)
        let (sut, _, router) = makeSUT(song: song)

        sut.viewAlbum()

        #expect(router.path.count == 1)
    }

    @Test func viewAlbum_dismissesSheet() {
        let song = Song.fixture(collectionId: 42)
        let (sut, _, router) = makeSUT(song: song)
        router.present(.moreOptions(song))

        sut.viewAlbum()

        #expect(router.sheet == nil)
    }
}

// MARK: - Helpers

private extension MoreOptionsViewModelTests {
    typealias SUTBundle = (sut: MoreOptionsViewModel, song: Song, router: AppRouter)

    func makeSUT(
        song: Song = .fixture(),
        source: SourceLocation = #_sourceLocation
    ) -> SUTBundle {
        let router = AppRouter()
        let sut = MoreOptionsViewModel(song: song, router: router)
        _ = source
        return (sut, song, router)
    }
}

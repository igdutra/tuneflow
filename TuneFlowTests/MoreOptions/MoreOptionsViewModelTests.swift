import Foundation
import Testing
import TuneDomain
@testable import TuneFlow

@MainActor
struct MoreOptionsViewModelTests {

    // MARK: - Display Properties

    @Test func init_exposesCorrectSongTitle() {
        let (sut, song) = makeSUT(song: .fixture(trackName: "Purple Rain"))

        #expect(sut.songTitle == song.trackName)
    }

    @Test func init_exposesCorrectArtistName() {
        let (sut, song) = makeSUT(song: .fixture(artistName: "Prince"))

        #expect(sut.artistName == song.artistName)
    }

    // MARK: - viewAlbum stub

    @Test func viewAlbum_doesNotMutateDisplayProperties() {
        let (sut, song) = makeSUT()

        sut.viewAlbum()

        #expect(sut.songTitle == song.trackName)
        #expect(sut.artistName == song.artistName)
    }
}

// MARK: - Helpers

private extension MoreOptionsViewModelTests {
    typealias SUTBundle = (sut: MoreOptionsViewModel, song: Song)

    func makeSUT(
        song: Song = .fixture(),
        source: SourceLocation = #_sourceLocation
    ) -> SUTBundle {
        let sut = MoreOptionsViewModel(song: song)
        _ = source
        return (sut, song)
    }
}

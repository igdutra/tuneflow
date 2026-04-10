import Testing
import TuneDomain
@testable import TuneFlow
internal import SwiftUI

@MainActor
struct SongsViewModelNavigationTests {

    @Test func selectSong_pushesPlayerRoute() {
        let (sut, _, router) = makeSUT()
        let song = Song.fixture()

        sut.selectSong(song)

        #expect(router.path.count == 1)
    }

    @Test func selectSong_calledTwice_pushesEachRoute() {
        let (sut, _, router) = makeSUT()

        sut.selectSong(.fixture(id: 1))
        sut.selectSong(.fixture(id: 2))

        #expect(router.path.count == 2)
    }
}

// MARK: - Helpers

private extension SongsViewModelNavigationTests {
    typealias SUTBundle = (sut: SongsViewModel, spy: SongRepositorySpy, router: AppRouter)

    func makeSUT(source: SourceLocation = #_sourceLocation) -> SUTBundle {
        let spy = SongRepositorySpy()
        let router = AppRouter()
        let sut = SongsViewModel(repository: spy, router: router)
        _ = source
        return (sut, spy, router)
    }
}

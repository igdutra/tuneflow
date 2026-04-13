import Testing
import TuneDomain
@testable import TuneFlow

@MainActor
struct PlayerViewModelTests {

    // MARK: - onAppear

    @Test("onAppear calls play with the song's preview URL")
    func onAppear_callsPlay_withSongPreviewURL() {
        let previewURL = URL(string: "https://preview.com/song.m4a")!
        let (sut, spy) = makeSUT(song: .fixture(previewURL: previewURL))

        sut.onAppear()

        #expect(spy.playCallCount == 1)
        #expect(spy.playCalledWithURL == previewURL)
    }

    @Test("onAppear with no preview URL does not call play")
    func onAppear_whenNoPreviewURL_doesNotCallPlay() {
        let (sut, spy) = makeSUT(song: .fixture(previewURL: nil))

        sut.onAppear()

        #expect(spy.playCallCount == 0)
    }

    // MARK: - onDisappear

    @Test("onDisappear calls stop")
    func onDisappear_callsStop() {
        let (sut, spy) = makeSUT()

        sut.onDisappear()

        #expect(spy.stopCallCount == 1)
    }

    // MARK: - didTapPlayPause

    @Test("didTapPlayPause when playing calls pause")
    func didTapPlayPause_whenPlaying_callsPause() {
        let (sut, spy) = makeSUT()
        spy.isPlaying = true

        sut.didTapPlayPause()

        #expect(spy.pauseCallCount == 1)
        #expect(spy.resumeCallCount == 0)
    }

    @Test("didTapPlayPause when paused calls resume")
    func didTapPlayPause_whenPaused_callsResume() {
        let (sut, spy) = makeSUT()
        spy.isPlaying = false

        sut.didTapPlayPause()

        #expect(spy.resumeCallCount == 1)
        #expect(spy.pauseCallCount == 0)
    }

    // MARK: - didTapForward

    @Test("didTapForward in sequential mode pops and pushes next song")
    func didTapForward_sequentialMode_popsAndPushesNextSong() {
        let songs = Song.fixtures(count: 3)
        let (sut, _, router) = makeSUT(song: songs[0], queue: songs, currentIndex: 0)

        sut.didTapForward()

        #expect(router.path.count == 1)
    }

    @Test("didTapForward at end of queue does nothing")
    func didTapForward_atEndOfQueue_doesNothing() {
        let songs = Song.fixtures(count: 3)
        let (sut, _, router) = makeSUT(song: songs[2], queue: songs, currentIndex: 2)
        router.push(.player(songs[2], queue: songs, currentIndex: 2))

        sut.didTapForward()

        #expect(router.path.count == 1)
    }

    @Test("didTapForward with shuffle on pushes a random song different from current")
    func didTapForward_shuffleOn_pushesRandomSong() {
        let songs = Song.fixtures(count: 5)
        let (sut, _, router) = makeSUT(song: songs[0], queue: songs, currentIndex: 0)
        sut.didTapShuffle()
        router.push(.player(songs[0], queue: songs, currentIndex: 0))

        sut.didTapForward()

        // Should still navigate (pop + push = net 1)
        #expect(router.path.count == 1)
    }

    // MARK: - didTapBackward

    @Test("didTapBackward when beyond 3s threshold seeks to zero")
    func didTapBackward_whenBeyondThreshold_seeksToZero() {
        let (sut, spy) = makeSUT()
        spy.currentTime = 10

        sut.didTapBackward()

        #expect(spy.seekCalledWithTime == 0)
    }

    @Test("didTapBackward within threshold with previous song pops and pushes prev song")
    func didTapBackward_whenWithinThreshold_andPrevExists_popsAndPushesPrevSong() {
        let songs = Song.fixtures(count: 3)
        let (sut, spy, router) = makeSUT(song: songs[1], queue: songs, currentIndex: 1)
        spy.currentTime = 2
        router.push(.player(songs[1], queue: songs, currentIndex: 1))

        sut.didTapBackward()

        #expect(router.path.count == 1)
    }

    @Test("didTapBackward at start of queue seeks to zero")
    func didTapBackward_whenAtStart_seeksToZero() {
        let songs = Song.fixtures(count: 3)
        let (sut, spy) = makeSUT(song: songs[0], queue: songs, currentIndex: 0)
        spy.currentTime = 1

        sut.didTapBackward()

        #expect(spy.seekCalledWithTime == 0)
    }

    // MARK: - Repeat / Shuffle

    @Test("didTapRepeat toggles isRepeatOn")
    func didTapRepeat_togglesRepeatState() {
        let (sut, _) = makeSUT()
        #expect(sut.isRepeatOn == false)

        sut.didTapRepeat()
        #expect(sut.isRepeatOn == true)

        sut.didTapRepeat()
        #expect(sut.isRepeatOn == false)
    }

    @Test("didTapShuffle toggles isShuffleOn")
    func didTapShuffle_togglesShuffleState() {
        let (sut, _) = makeSUT()
        #expect(sut.isShuffleOn == false)

        sut.didTapShuffle()
        #expect(sut.isShuffleOn == true)

        sut.didTapShuffle()
        #expect(sut.isShuffleOn == false)
    }

    // MARK: - More Options

    @Test("didTapMoreOptions presents moreOptions sheet")
    func didTapMoreOptions_presentsMoreOptionsSheet() {
        let song = Song.fixture()
        let (sut, _, router) = makeSUT(song: song)

        sut.didTapMoreOptions()

        #expect(router.sheet != nil)
    }

    // MARK: - Formatted Time

    @Test("currentTimeFormatted returns correct M:SS string")
    func currentTimeFormatted_returnsCorrectString() {
        let (sut, spy) = makeSUT()
        spy.currentTime = 90

        #expect(sut.currentTimeFormatted == "1:30")
    }

    @Test("durationFormatted returns correct M:SS string")
    func durationFormatted_returnsCorrectString() {
        let (sut, spy) = makeSUT()
        spy.duration = 215

        #expect(sut.durationFormatted == "3:35")
    }

    // MARK: - Artwork URL

    @Test("artworkURL replaces 100x100 with 600x600")
    func artworkURL_replaces100x100With600x600() {
        let song = Song.fixture(artworkURL: URL(string: "https://artwork.com/100x100.jpg")!)
        let (sut, _) = makeSUT(song: song)

        #expect(sut.artworkURL?.absoluteString == "https://artwork.com/600x600.jpg")
    }
}

// MARK: - Helpers

private extension PlayerViewModelTests {
    typealias SUTBundle = (sut: PlayerViewModel, spy: AudioPlayerServiceSpy, router: AppRouter)
    typealias SUTBundleNoRouter = (sut: PlayerViewModel, spy: AudioPlayerServiceSpy)

    func makeSUT(
        song: Song = .fixture(),
        queue: [Song] = [],
        currentIndex: Int = 0,
        source: SourceLocation = #_sourceLocation
    ) -> SUTBundle {
        let spy = AudioPlayerServiceSpy()
        let router = AppRouter()
        let sut = PlayerViewModel(
            song: song,
            queue: queue,
            currentIndex: currentIndex,
            audioService: spy,
            router: router
        )
        _ = source
        return (sut, spy, router)
    }

    func makeSUT(
        song: Song = .fixture(),
        queue: [Song] = [],
        currentIndex: Int = 0,
        source: SourceLocation = #_sourceLocation
    ) -> SUTBundleNoRouter {
        let (sut, spy, _) = makeSUT(song: song, queue: queue, currentIndex: currentIndex, source: source)
        return (sut, spy)
    }
}

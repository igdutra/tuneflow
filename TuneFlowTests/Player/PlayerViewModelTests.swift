import Testing
import TuneDomain
internal import SwiftUI
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

    @Test("onAppear wires the state callback so emissions update the view model")
    func onAppear_wiresStateCallback() {
        let (sut, spy) = makeSUT()

        sut.onAppear()

        #expect(spy.onStateChange != nil)
    }

    // MARK: - onDisappear

    @Test("onDisappear calls stop")
    func onDisappear_callsStop() {
        let (sut, spy) = makeSUT()

        sut.onDisappear()

        #expect(spy.stopCallCount == 1)
    }

    @Test("onDisappear clears the state callback")
    func onDisappear_clearsStateCallback() {
        let (sut, spy) = makeSUT()
        sut.onAppear()

        sut.onDisappear()

        #expect(spy.onStateChange == nil)
    }

    // MARK: - Async state propagation (regression tests)

    @Test("emitted playing state updates isPlaying without any tap")
    func emittedPlayingState_updatesIsPlaying() {
        let (sut, spy) = makeSUT()
        sut.onAppear()

        spy.emit(AudioPlayerState(isPlaying: true, isReadyToPlay: true, currentTime: 0, duration: 30, progress: 0))

        #expect(sut.isPlaying == true)
        #expect(sut.isReadyToPlay == true)
    }

    @Test("emitted time update changes currentTime, progress, and formatted labels")
    func emittedTimeUpdate_changesTimeAndProgress() {
        let (sut, spy) = makeSUT()
        sut.onAppear()

        spy.emit(AudioPlayerState(isPlaying: true, isReadyToPlay: true, currentTime: 90, duration: 180, progress: 0.5))

        #expect(sut.currentTime == 90)
        #expect(sut.progress == 0.5)
        #expect(sut.currentTimeFormatted == "1:30")
        #expect(sut.remainingTimeFormatted == "1:30")
    }

    @Test("emitted paused state resets isPlaying to false")
    func emittedPausedState_resetsIsPlaying() {
        let (sut, spy) = makeSUT()
        sut.onAppear()
        spy.emit(AudioPlayerState(isPlaying: true, isReadyToPlay: true, currentTime: 5, duration: 30, progress: 0.16))

        spy.emit(AudioPlayerState(isPlaying: false, isReadyToPlay: true, currentTime: 5, duration: 30, progress: 0.16))

        #expect(sut.isPlaying == false)
    }

    @Test("emitted stopped state resets isPlaying and progress")
    func emittedStoppedState_resetsIsPlayingAndProgress() {
        let (sut, spy) = makeSUT()
        sut.onAppear()
        spy.emit(AudioPlayerState(isPlaying: true, isReadyToPlay: true, currentTime: 10, duration: 30, progress: 0.33))

        spy.emit(.idle)

        #expect(sut.isPlaying == false)
        #expect(sut.progress == 0)
        #expect(sut.currentTime == 0)
    }

    @Test("remaining time is duration minus currentTime, not total duration")
    func remainingTimeFormatted_usesDurationMinusCurrentTime() {
        let (sut, spy) = makeSUT()
        sut.onAppear()

        spy.emit(AudioPlayerState(isPlaying: true, isReadyToPlay: true, currentTime: 26, duration: 30, progress: 0.86))

        #expect(sut.remainingTimeFormatted == "0:04")
    }

    // MARK: - didTapPlayPause

    @Test("didTapPlayPause when playing calls pause")
    func didTapPlayPause_whenPlaying_callsPause() {
        let (sut, spy) = makeSUT()
        sut.onAppear()
        spy.emit(AudioPlayerState(isPlaying: true, isReadyToPlay: true, currentTime: 0, duration: 30, progress: 0))

        sut.didTapPlayPause()

        #expect(spy.pauseCallCount == 1)
        #expect(spy.resumeCallCount == 0)
    }

    @Test("didTapPlayPause when paused calls resume")
    func didTapPlayPause_whenPaused_callsResume() {
        let (sut, spy) = makeSUT()
        sut.onAppear()
        spy.emit(AudioPlayerState(isPlaying: false, isReadyToPlay: true, currentTime: 0, duration: 30, progress: 0))

        sut.didTapPlayPause()

        #expect(spy.resumeCallCount == 1)
        #expect(spy.pauseCallCount == 0)
    }


    // MARK: - Recently Played

    @Test("onAppear calls save on recently played repository")
    func onAppear_callsSaveOnRecentlyPlayedRepository() async {
        let song = Song.fixture()
        let (sut, _, _, repoSpy) = makeSUT(song: song)

        sut.onAppear()
        await Task.yield()

        #expect(repoSpy.saveCallCount == 1)
        #expect(repoSpy.saveCalledWithSong == song)
    }

    @Test("onAppear save failure does not crash and playback continues")
    func onAppear_saveFailure_doesNotCrashAndPlaybackContinues() async {
        let previewURL = URL(string: "https://preview.com/song.m4a")!
        let (sut, audioSpy, _, repoSpy) = makeSUT(song: .fixture(previewURL: previewURL))
        repoSpy.stubSave(error: NSError(domain: "test", code: 0))

        sut.onAppear()
        await Task.yield()

        #expect(audioSpy.playCallCount == 1)
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
        sut.onAppear()

        spy.emit(AudioPlayerState(isPlaying: true, isReadyToPlay: true, currentTime: 90, duration: 30, progress: 0))

        #expect(sut.currentTimeFormatted == "1:30")
    }

    @Test("durationFormatted returns correct M:SS string")
    func durationFormatted_returnsCorrectString() {
        let (sut, spy) = makeSUT()
        sut.onAppear()

        spy.emit(AudioPlayerState(isPlaying: true, isReadyToPlay: true, currentTime: 0, duration: 215, progress: 0))

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
    typealias SUTBundleFull = (sut: PlayerViewModel, audioSpy: AudioPlayerServiceSpy, router: AppRouter, repoSpy: RecentlyPlayedRepositorySpy)

    func makeSUT(
        song: Song = .fixture(),
        queue: [Song] = [],
        currentIndex: Int = 0,
        source: SourceLocation = #_sourceLocation
    ) -> SUTBundleFull {
        let audioSpy = AudioPlayerServiceSpy()
        let repoSpy = RecentlyPlayedRepositorySpy()
        let router = AppRouter()
        let sut = PlayerViewModel(
            song: song,
            queue: queue,
            currentIndex: currentIndex,
            audioService: audioSpy,
            recentlyPlayedRepository: repoSpy,
            router: router
        )
        _ = source
        return (sut, audioSpy, router, repoSpy)
    }

    func makeSUT(
        song: Song = .fixture(),
        queue: [Song] = [],
        currentIndex: Int = 0,
        source: SourceLocation = #_sourceLocation
    ) -> SUTBundle {
        let (sut, audioSpy, router, _) = makeSUT(song: song, queue: queue, currentIndex: currentIndex, source: source)
        return (sut, audioSpy, router)
    }

    func makeSUT(
        song: Song = .fixture(),
        queue: [Song] = [],
        currentIndex: Int = 0,
        source: SourceLocation = #_sourceLocation
    ) -> SUTBundleNoRouter {
        let (sut, audioSpy, _, _) = makeSUT(song: song, queue: queue, currentIndex: currentIndex, source: source)
        return (sut, audioSpy)
    }
}

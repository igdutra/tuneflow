import AVFoundation
import SwiftData
import SwiftUI
import TuneAPI
import TuneDomain


@main
struct TuneFlowApp: App {
    private let httpClient = URLSessionHTTPClient()
    private let songRepository: any SongRepository
    private let audioService = AVAudioPlayerService()
    private let recentlyPlayedRepository: any RecentlyPlayedRepository
    private let eventTracker: EventTracker = InMemoryAnalyticsTracker()
    private let logHandler: LogHandling = OSLogger()

    init() {
        AVPlayer.isObservationEnabled = true
        let baseURL = URL(string: "https://itunes.apple.com/search")!
        let lookupBaseURL = URL(string: "https://itunes.apple.com/lookup")!
        songRepository = RemoteSongRepository(
            client: httpClient,
            baseURL: baseURL,
            lookupBaseURL: lookupBaseURL,
            logger: logHandler
        )

        let container = try! ModelContainer(for: StoredSong.self, StoredPlayHistory.self)
        let store = SwiftDataRecentlyPlayedStore(modelContainer: container)
        recentlyPlayedRepository = LocalRecentlyPlayedRepository(store: store)
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                songRepository: songRepository,
                audioService: audioService,
                trackPlayerScreenViewed: makeTrackPlayerScreenViewed(),
                recentlyPlayedRepository: recentlyPlayedRepository
            )
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Observability

public typealias TrackPlayerScreenViewed = (Song) -> Void

// Note: The reasoning behing making a closure and injecting down is for TuneUI (that can be moved to separate module) to remain agnostic of Analytics details and the PlayerEvent lives in the Main App.
// We could make the case that TuneUI is fine to have PlayerEvent and we simply inject an implementation of `EventTracker`.
// It depends on what we want to achieve!
private extension TuneFlowApp {
    func makeTrackPlayerScreenViewed() -> TrackPlayerScreenViewed {
        { [weak eventTracker] song in
            eventTracker?.track(PlayerEvent.screenViewed(songName: song.trackName, artist: song.artistName))
        }
    }
}

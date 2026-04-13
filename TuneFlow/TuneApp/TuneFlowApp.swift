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

    init() {
        AVPlayer.isObservationEnabled = true
        let baseURL = URL(string: "https://itunes.apple.com/search")!
        let lookupBaseURL = URL(string: "https://itunes.apple.com/lookup")!
        songRepository = RemoteSongRepository(client: httpClient, baseURL: baseURL, lookupBaseURL: lookupBaseURL)

        let container = try! ModelContainer(for: StoredSong.self, StoredPlayHistory.self)
        let store = SwiftDataRecentlyPlayedStore(modelContainer: container)
        recentlyPlayedRepository = LocalRecentlyPlayedRepository(store: store)
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                songRepository: songRepository,
                audioService: audioService,
                trackPlayerScreenViewed: { [weak eventTracker] song in
                    eventTracker?.track(PlayerEvent.screenViewed(songName: song.trackName, artist: song.artistName))
                },
                recentlyPlayedRepository: recentlyPlayedRepository
            )
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Observability

public typealias TrackPlayerScreenViewed = (Song) -> Void

private extension TuneFlowApp {
    func trackPlayerScreenViewed(_ song: Song) {
        eventTracker.track(PlayerEvent.screenViewed(songName: song.trackName, artist: song.artistName))
    }
}

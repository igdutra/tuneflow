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
                recentlyPlayedRepository: recentlyPlayedRepository
            )
            .preferredColorScheme(.dark)
        }
    }
}

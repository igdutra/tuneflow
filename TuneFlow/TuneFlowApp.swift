import SwiftUI
import TuneAPI
import TuneDomain

@main
struct TuneFlowApp: App {
    private let httpClient = URLSessionHTTPClient()
    private let songRepository: any SongRepository

    init() {
        let baseURL = URL(string: "https://itunes.apple.com/search")!
        let lookupBaseURL = URL(string: "https://itunes.apple.com/lookup")!
        songRepository = RemoteSongRepository(client: httpClient, baseURL: baseURL, lookupBaseURL: lookupBaseURL)
    }

    var body: some Scene {
        WindowGroup {
            RootView(songRepository: songRepository)
                .preferredColorScheme(.dark)
        }
    }
}

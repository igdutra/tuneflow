import SwiftUI
import TuneAPI
import TuneDomain

@main
struct TuneFlowApp: App {
    private let httpClient = URLSessionHTTPClient()
    private let songRepository: any SongRepository

    init() {
        let baseURL = URL(string: "https://itunes.apple.com/search")!
        songRepository = RemoteSongRepository(client: httpClient, baseURL: baseURL)
    }

    var body: some Scene {
        WindowGroup {
            RootView(songRepository: songRepository)
                .preferredColorScheme(.dark)
        }
    }
}

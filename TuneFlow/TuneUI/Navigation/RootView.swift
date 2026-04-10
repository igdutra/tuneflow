import SwiftUI
import TuneDomain

struct RootView: View {
    private let songRepository: any SongRepository
    @State private var router = AppRouter()

    init(songRepository: any SongRepository) {
        self.songRepository = songRepository
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            SongsComposer.compose(songRepository: songRepository, router: router)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .player(let song):
                        Text("Player — \(song.trackName)") // Track 5 placeholder
                    }
                }
        }
        .sheet(item: $router.sheet) { sheet in
            switch sheet {
            case .moreOptions(let song):
                Text("More options — \(song.trackName)") // Track 6 placeholder
            }
        }
        .environment(router)
    }
}

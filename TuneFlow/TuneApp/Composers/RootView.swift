import SwiftUI
import TuneDomain

struct RootView: View {
    private let songRepository: any SongRepository
    private let audioService: any AudioPlayerService
    private let recentlyPlayedRepository: any RecentlyPlayedRepository
    @State private var router = AppRouter()

    init(
        songRepository: any SongRepository,
        audioService: any AudioPlayerService,
        recentlyPlayedRepository: any RecentlyPlayedRepository
    ) {
        self.songRepository = songRepository
        self.audioService = audioService
        self.recentlyPlayedRepository = recentlyPlayedRepository
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            SongsComposer.compose(
                songRepository: songRepository,
                recentlyPlayedRepository: recentlyPlayedRepository,
                router: router
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .player(let song, let queue, let currentIndex):
                    PlayerComposer.compose(
                        song: song,
                        queue: queue,
                        currentIndex: currentIndex,
                        audioService: audioService,
                        recentlyPlayedRepository: recentlyPlayedRepository,
                        router: router
                    )
                case .album(let collectionId):
                    AlbumComposer.compose(
                        collectionId: collectionId,
                        songRepository: songRepository,
                        router: router
                    )
                }
            }
        }
        .sheet(item: $router.sheet) { sheet in
            switch sheet {
            case .moreOptions(let song):
                MoreOptionsView(viewModel: MoreOptionsViewModel(song: song, router: router))
            }
        }
        .environment(router)
    }
}

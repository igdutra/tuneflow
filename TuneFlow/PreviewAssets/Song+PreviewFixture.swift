import Foundation
import TuneDomain

/// Note: This is inside a folder that is set as Development Assets. This will be stript on release builds.
extension Song {
    static let previewFixture = Song(
        id: 1544491998,
        trackName: "Upside Down",
        artistName: "Jack Johnson",
        albumName: "Jack Johnson and Friends: Sing-A-Longs and Lullabies for the Film Curious George",
        collectionId: 1544491465,
        artworkURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/08/11/d2/0811d2b3-b4d5-dc22-1107-3625511844b5/00602537869770.rgb.jpg/100x100bb.jpg")!,
        previewURL: URL(string: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview116/v4/54/3b/02/543b02a0-c567-7787-4ea1-c56aa282631a/mzaf_5094094558437262237.plus.aac.p.m4a"),
        trackNumber: 11
    )
}

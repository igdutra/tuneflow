import SwiftUI

struct SongRowView: View {
    let artworkURL: URL
    let title: String
    let artist: String
    let onMoreTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // TODO: For custom image cache strategy we could create our own component and image loader component (with cache)
            AsyncImage(url: artworkURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .foregroundStyle(Color(white: 0.2))
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(artist)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(hex: "#737373"))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onMoreTapped) {
                Image(systemName: "ellipsis")
                    .foregroundStyle(Color.white.opacity(0.34))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 5)
    }
}

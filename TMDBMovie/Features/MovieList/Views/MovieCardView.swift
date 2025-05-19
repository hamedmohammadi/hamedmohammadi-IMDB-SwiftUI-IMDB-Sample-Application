import SwiftUI

struct MovieCardView: View {
    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: APIConstants.imageURL(path: movie.posterPath, size: .w300)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Rectangle().fill(Color.secondary.opacity(0.1))
                        ProgressView()
                    }
                case .success(let image):
                    image.resizable()
                case .failure:
                    ZStack {
                        Rectangle().fill(Color.secondary.opacity(0.2))
                        Image(systemName: "film")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    }
                @unknown default: EmptyView()
                }
            }
            .aspectRatio(2/3, contentMode: .fill)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title ?? "N/A")
                    .font(.headline)
                    .lineLimit(2)
                HStack {
                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                    Text(String(format: "%.1f", movie.voteAverage ?? 0.0))
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                }

                Text(movie.releaseDate?.toDate()?.formatted(dateStyle: .medium) ?? movie.releaseDate ?? "N/A")
                    .font(.caption).foregroundColor(.gray)
            }
            .padding([.horizontal, .bottom], 10).padding(.top, 6)
        }
        .background(Material.regular)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

struct MovieCardView_Previews: PreviewProvider {
    static var previews: some View {
        MovieCardView(movie: Movie.mock)
            .frame(width: 200)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

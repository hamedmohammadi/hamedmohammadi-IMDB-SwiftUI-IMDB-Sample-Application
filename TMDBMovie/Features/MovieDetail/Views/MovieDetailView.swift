import SwiftUI

struct MovieDetailView: View {
    @StateObject private var viewModel: MovieDetailViewModel
    let movieTitle: String?

    init(movieId: Int, movieTitle: String?) {
        _viewModel = StateObject(wrappedValue: MovieDetailViewModel(movieId: movieId))
        self.movieTitle = movieTitle
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading && viewModel.movieDetail == nil {
                    LoadingIndicatorView().frame(maxWidth: .infinity, alignment: .center)
                } else if let detail = viewModel.movieDetail {
                    movieHeader(for: detail)
                    Group {
                        movieOverview(for: detail)
                        movieInformation(for: detail)
                        movieCast(for: detail.credits?.cast)
                        movieTrailers(for: detail.videos?.results)
                    }.padding()
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage) {
                        Task { await viewModel.fetchDetails() }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.movieDetail?.title ?? movieTitle ?? "Details")
        .task {
            await viewModel.fetchDetails()
        }
        #if os(macOS)
        .frame(minWidth: 400, idealWidth: 600, minHeight: 500)
        #endif
    }

    @ViewBuilder
    private func movieHeader(for detail: MovieDetail) -> some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: APIConstants.imageURL(path: detail.backdropPath, size: .w780)) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else if phase.error != nil {
                    Color.secondary.opacity(0.2)
                } else {
                    Color.secondary.opacity(0.1).overlay(ProgressView())
                }
            }
            .frame(height: 250)
            .clipped()
            .overlay(LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                startPoint: .center,
                endPoint: .bottom))

            HStack(alignment: .bottom, spacing: 16) {
                AsyncImage(url: APIConstants.imageURL(path: detail.posterPath, size: .w300)) { phase in
                    if let image = phase.image {
                        image.resizable()
                    } else {
                        Color.gray
                            .opacity(0.3)
                            .overlay(phase.error != nil ? AnyView(Image(systemName: "film")) : AnyView(ProgressView()))
                    }
                }
                .frame(width: 100, height: 150)
                .aspectRatio(2/3, contentMode: .fit)
                .clipped()
                .cornerRadius(8)
                .shadow(radius: 5)

                VStack(alignment: .leading) {
                    Text(detail.title ?? "N/A")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                    if let tagline = detail.tagline, !tagline.isEmpty {
                        Text(tagline)
                            .font(.headline)
                            .italic()
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(radius: 1)
                    }
                }
                Spacer()
            }
            .padding()
        }
    }

    @ViewBuilder
    private func movieOverview(for detail: MovieDetail) -> some View {
        Group {
            Text("Overview").font(.title2).fontWeight(.semibold)
            Text(detail.overview ?? "No overview available.")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func movieInformation(for detail: MovieDetail) -> some View {
        Group {
            Text("Information").font(.title2).fontWeight(.semibold)
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: "Release Date",
                            value: detail.releaseDate?.toDate()?.formatted() ?? "N/A")
                    InfoRow(label: "Rating",
                            value: detail.ratingDescription)
                    InfoRow(label: "Runtime",
                            value: detail.runtime != nil ? "\(detail.runtime!) min" : "N/A")
                }
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: "Status", value: detail.status ?? "N/A")
                    InfoRow(label: "Genres", value: detail.genres?.map(\.name).joined(separator: ", ") ?? "N/A")
                    if let budget = detail.budget, budget > 0 {
                        InfoRow(label: "Budget", value: "$\(budget.formatted(.number))")
                    }
                    if let revenue = detail.revenue, revenue > 0 {
                         InfoRow(label: "Revenue", value: "$\(revenue.formatted(.number))")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func movieCast(for cast: [CastMember]?) -> some View {
        if let cast = cast, !cast.isEmpty {
            VStack(alignment: .leading) {
                Text("Cast").font(.title2).fontWeight(.semibold)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(cast.prefix(10)) { member in
                            VStack {
                                AsyncImage(url: APIConstants.imageURL(path: member.profilePath, size: .w200)) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Color.gray.opacity(0.2).overlay(Image(systemName: "person.fill"))
                                    }
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                Text(member.name ?? "").font(.caption).lineLimit(1)
                                Text(member.character ?? "").font(.caption2).foregroundColor(.secondary).lineLimit(1)
                            }
                            .frame(width: 90)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func movieTrailers(for videos: [Video]?) -> some View {
        if let trailers = videos?.filter({ $0.site == "YouTube" && ($0.type == "Trailer" || $0.type == "Teaser") }),
           !trailers.isEmpty {
            VStack(alignment: .leading) {
                Text("Trailers").font(.title2).fontWeight(.semibold)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(trailers) { video in
                            if let url = video.youtubeURL {
                                Link(destination: url) {
                                    ZStack {
                                        Rectangle().fill(Color.black)
                                        Image(systemName: "play.rectangle.fill")
                                            .foregroundColor(.white).font(.largeTitle)
                                        Text(video.name ?? "Trailer")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                            .padding(4)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                    }
                                    .frame(width: 200, height: 112.5)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

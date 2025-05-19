import Foundation

// MARK: - Movie List Response
struct MovieResponse: Codable {
    let page: Int
    let results: [Movie]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

// MARK: - Movie
struct Movie: Codable, Identifiable, Hashable, Equatable {
    let id: Int
    let title: String?
    let originalTitle: String?
    let overview: String?
    let originalLanguage: String?
    let adult: Bool?
    let backdropPath: String?
    let popularity: Double?
    let posterPath: String?
    let releaseDate: String? // "YYYY-MM-DD"
    let video: Bool?
    let voteAverage: Double?
    let voteCount: Int?
    let genreIds: [Int]?

    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case genreIds = "genre_ids"
        case id
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case overview, popularity
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case title, video
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }

    static var mock: Movie {
        Movie(
            id: 1011985,
            title: "Kung Fu Panda 4",
            originalTitle: "Kung Fu Panda 4",
            overview: "Po is gearing up to become the spiritual leader of his Valley of Peace...",
            originalLanguage: "en",
            adult: false,
            backdropPath: "/1XDDXPXGiI8id7MrUxK36ke7gkX.jpg",
            popularity: 4240.617,
            posterPath: "/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg",
            releaseDate: "2024-03-02",
            video: false,
            voteAverage: 6.9,
            voteCount: 278,
            genreIds: [28, 12, 16, 35, 10751])
    }
}

// MARK: - Movie Detail
struct MovieDetail: Codable, Identifiable {
    let id: Int
    let imdbId: String?
    let title: String?
    let originalTitle: String?
    let overview: String?
    let originalLanguage: String?
    let adult: Bool?
    let backdropPath: String?
    let budget: Int?
    let genres: [Genre]?
    let homepage: String?
    let popularity: Double?
    let posterPath: String?
    let releaseDate: String?
    let revenue: Int?
    let runtime: Int?
    let status: String?
    let tagline: String?
    let voteAverage: Double?
    let voteCount: Int?
    let credits: Credits?
    let videos: VideoResponse?

    enum CodingKeys: String, CodingKey {
        case adult, budget, genres, homepage, id, overview, popularity, revenue,
             runtime, status, tagline, title, credits, videos
        case backdropPath = "backdrop_path"
        case imdbId = "imdb_id"
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }

    var ratingDescription: String {
        String(format: "%.1f/10", voteAverage ?? 0) + " (\(voteCount ?? 0) votes)"
    }

    static var mock: MovieDetail {
        MovieDetail(
            id: 1011985,
            imdbId: "tt21692408",
            title: "Kung Fu Panda 4",
            originalTitle: "Kung Fu Panda 4",
            overview: "Po is gearing up...",
            originalLanguage: "en",
            adult: false,
            backdropPath: "/1XDDXPXGiI8id7MrUxK36ke7gkX.jpg",
            budget: 85000000,
            genres: [Genre(id: 28, name: "Action")],
            homepage: "https://site.com",
            popularity: 4240.617,
            posterPath: "/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg",
            releaseDate: "2024-03-02",
            revenue: 268000000,
            runtime: 94,
            status: "Released",
            tagline: "The Dragon Warrior is back.",
            voteAverage: 6.9,
            voteCount: 278,
            credits: Credits.mock,
            videos: VideoResponse.mock)
    }
}

struct Genre: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
}

struct Credits: Codable, Hashable {
    let cast: [CastMember]?
    let crew: [CrewMember]?
    static var mock: Credits { Credits(cast: [CastMember.mock], crew: [])}
}

struct CastMember: Codable, Identifiable, Hashable {
    let id: Int
    let name: String?
    let character: String?
    let profilePath: String?
    enum CodingKeys: String, CodingKey { case id, name, character; case profilePath = "profile_path"}
    static var mock: CastMember { CastMember(id: 1, name: "Actor Name", character: "Role", profilePath: nil) }
}

struct CrewMember: Codable, Identifiable, Hashable {
    let id: Int
    let name: String?
    let job: String?
    enum CodingKeys: String, CodingKey { case id, name, job }
}

struct VideoResponse: Codable, Hashable {
    let results: [Video]?
    static var mock: VideoResponse { VideoResponse(results: [Video.mock]) }
}

struct Video: Codable, Identifiable, Hashable {
    let id: String
    let key: String?
    let name: String?
    let site: String?
    let type: String?
    var youtubeURL: URL? {
        (site == "YouTube" && key != nil) ? URL(string: "https://www.youtube.com/watch?v=\(key!)") : nil
    }
    static var mock: Video {
        Video(id: "1", key: "key", name: "Trailer", site: "YouTube", type: "Trailer")
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case httpError(statusCode: Int)
    case custom(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL."
        case .requestFailed(let error): "Request failed: \(error.localizedDescription)"
        case .invalidResponse: "Invalid server response."
        case .decodingError(let error): "Decoding error: \(error.localizedDescription). Details: \(error)"
        case .httpError(let statusCode): "HTTP error: \(statusCode)."
        case .custom(let message): message
        }
    }
}

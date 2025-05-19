import Foundation
enum APIConstants {
    static var apiBearerToken: String = {
        guard let token = Bundle.main.infoDictionary?["MOVIEDB_API_TOKEN"] as? String,
              !token.isEmpty else {
            fatalError("Missing MOVIEDB_API_TOKEN – add it to Secrets.xcconfig")
        }
        return token
    }()

    static let baseURL = "https://api.themoviedb.org/3"
    static let imageBaseURL = "https://image.tmdb.org/t/p/"

    enum ImageSize: String {
        case original, w200, w300, w500, w780
    }

    enum Endpoints {
        static let nowPlayingMoviesPath = "/movie/now_playing"
//        static let popularMoviesPath = "/movie/popular"

        static var searchMovies: (path: String, defaultQueryItems: [URLQueryItem]) {
            (
                path: "/search/movie",
                defaultQueryItems: [
                    URLQueryItem(name: "include_adult", value: "false")
                ]
            )
        }

        static func movieDetails(id: Int) -> (path: String, defaultQueryItems: [URLQueryItem]) {
            (
                path: "/movie/\(id)",
                defaultQueryItems: [
                    URLQueryItem(name: "append_to_response", value: "videos,credits")
                ]
            )
        }
    }

    static func imageURL(path: String?, size: ImageSize = .w500) -> URL? {
        guard let path = path, !path.isEmpty else { return nil }
        let fullPath = "\(imageBaseURL)\(size.rawValue)\(path.starts(with: "/") ? path : "/\(path)")"
        return URL(string: fullPath)
    }
}

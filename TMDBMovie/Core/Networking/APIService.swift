import Foundation

class APIService {
    static let shared = APIService()
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = URLSession(configuration: .default)) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    private func buildURL(endpointPath: String,
                          baseQueryItemsFromEndpoint: [URLQueryItem] = [],
                          additionalDynamicQueryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents(string: APIConstants.baseURL)
        components?.path += endpointPath

        let globalDefaultQueryItems = [URLQueryItem(name: "language", value: "en-US")]
        let combinedQueryItems = (globalDefaultQueryItems + baseQueryItemsFromEndpoint + additionalDynamicQueryItems)
                                   .uniquedByName()

        if !combinedQueryItems.isEmpty { components?.queryItems = combinedQueryItems }
        return components?.url
    }

    private func performRequest<T: Decodable>(url: URL?) async throws -> T {
        guard let url = url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(APIConstants.apiBearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            guard (200...299).contains(httpResponse.statusCode) else {
                print("HTTP Error: \(httpResponse.statusCode), URL: \(url.absoluteString)")
                if let errorDataString = String(data: data, encoding: .utf8) { print("Error data: \(errorDataString)")}
                throw APIError.httpError(statusCode: httpResponse.statusCode)
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error.localizedDescription), for URL: \(url.absoluteString)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Failed to decode JSON (first 500 chars): \(String(jsonString.prefix(500)))")
                }
                throw APIError.decodingError(error)
            }
        } catch {
            throw error is APIError ? error : APIError.requestFailed(error)
        }
    }

    func fetchNowPlayingMovies(page: Int = 1) async throws -> MovieResponse {
        let dynamicQueryItems = [URLQueryItem(name: "page", value: String(page))]
        let url = buildURL(endpointPath: APIConstants.Endpoints.nowPlayingMoviesPath,
                           additionalDynamicQueryItems: dynamicQueryItems)
        return try await performRequest(url: url)
    }

    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        let endpointInfo = APIConstants.Endpoints.movieDetails(id: id)
        let url = buildURL(endpointPath: endpointInfo.path,
                           baseQueryItemsFromEndpoint: endpointInfo.defaultQueryItems)
        return try await performRequest(url: url)
    }

    func searchMovies(query: String, page: Int = 1) async throws -> MovieResponse {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
             return MovieResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
        }
        let endpointInfo = APIConstants.Endpoints.searchMovies
        let dynamicQueryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page))
        ]
        let url = buildURL(endpointPath: endpointInfo.path,
                           baseQueryItemsFromEndpoint: endpointInfo.defaultQueryItems,
                           additionalDynamicQueryItems: dynamicQueryItems)
        return try await performRequest(url: url)
    }
}

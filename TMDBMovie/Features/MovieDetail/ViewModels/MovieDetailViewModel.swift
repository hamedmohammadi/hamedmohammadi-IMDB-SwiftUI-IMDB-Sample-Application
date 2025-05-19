import SwiftUI

@MainActor
class MovieDetailViewModel: ObservableObject {
    @Published var movieDetail: MovieDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let movieId: Int
    private let apiService: APIService

    init(movieId: Int, apiService: APIService = APIService.shared) {
        self.movieId = movieId
        self.apiService = apiService
    }

    func fetchDetails() async {
        guard movieDetail == nil else { return }
        isLoading = true
        errorMessage = nil

        do {
            movieDetail = try await apiService.fetchMovieDetail(id: movieId)
        } catch {
            let apiError = error as? APIError ?? APIError.custom("An unexpected error occurred.")
            errorMessage = apiError.localizedDescription
        }
        isLoading = false
    }
}

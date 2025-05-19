import SwiftUI

@MainActor
class MovieListViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoadingPage = false
    @Published var errorMessage: String?
    @Published var canLoadMorePages = true

    private var currentPage = 1 { didSet { print("current page: \(currentPage)")}}
    private var totalPages = Int.max
    private let apiService: APIService

    init(apiService: APIService = APIService.shared) {
        self.apiService = apiService
    }

    func loadInitialMovies() async {
        guard movies.isEmpty else { return }
        await fetchMovies(isRefresh: false)
    }

    func loadMoreMoviesIfNeeded(currentMovie: Movie?) async {
        guard let currentMovie = currentMovie else { return }
        guard !isLoadingPage, canLoadMorePages else { return }

        if let index = movies.firstIndex(where: { $0.id == currentMovie.id }) {
            let threshold = movies.count - 5
            if index >= threshold {
                await fetchMovies(isRefresh: false)
            }
        }
    }

    private func fetchMovies(isRefresh: Bool) async {
        guard !isLoadingPage && (canLoadMorePages || isRefresh) else { return }

        if isRefresh {
            movies = []
            currentPage = 1
            totalPages = Int.max
            canLoadMorePages = true
        }

        isLoadingPage = true
        errorMessage = nil
        do {
            let response = try await apiService.fetchNowPlayingMovies(page: currentPage)
            let newMovies = response.results.filter { newMovie in !movies.contains(where: { $0.id == newMovie.id })}
            movies.append(contentsOf: newMovies)
            totalPages = response.totalPages
            if currentPage < totalPages {
                currentPage += 1
                canLoadMorePages = true
            } else {
                canLoadMorePages = false
            }
        } catch {
            let apiError = error as? APIError ?? APIError.custom("An unexpected error occurred.")
            errorMessage = apiError.localizedDescription
        }
        isLoadingPage = false
    }

    func refreshMovies() async {
        await fetchMovies(isRefresh: true)
    }
}

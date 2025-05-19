import SwiftUI
import Combine

@MainActor
class MovieSearchViewModel: ObservableObject {
    // MARK: - Published Properties for UI State
    @Published var searchText: String = ""

    // Stage 1: Autocomplete Suggestions
    @Published var searchSuggestions: [Movie] = []
    @Published var isLoadingSuggestions: Bool = false

    // Stage 2: Full Search Results
    @Published var searchResults: [Movie] = []
    @Published var isLoadingResults: Bool = false
    @Published var isLoadingMoreResults: Bool = false
    @Published var canLoadMoreSearchResults = false

    // Shared State
    @Published var errorMessage: String?
    // Popular movies are no longer directly managed by this VM for the main view
    // as MovieListView will handle its own "default" content.

    // MARK: - Private Properties
    var committedSearchQuery: String = ""

    private let apiService: APIService
    private var textChangeCancellable: AnyCancellable?
    private var suggestionFetchTask: Task<Void, Never>?

    private var searchResultsCurrentPage = 1
    private var searchResultsTotalPages = 1

    // MARK: - Initialization
    init(apiService: APIService = .shared) {
        self.apiService = apiService

        textChangeCancellable = $searchText
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] currentText in
                guard let self = self else { return }
                let trimmedText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

                self.suggestionFetchTask?.cancel()

                if trimmedText.isEmpty {
                    self.clearAllSearchData()
                    self.errorMessage = nil
                } else if trimmedText.count < 2 {
                    self.searchSuggestions = []
                    if !self.committedSearchQuery.isEmpty { self.searchResults = [] }
                    self.errorMessage = "Type at least 2 characters..." // This message will be shown by the view
                    self.isLoadingSuggestions = false
                } else {
                    self.errorMessage = nil
                    self.suggestionFetchTask = Task {
                        await self.fetchSuggestions(for: trimmedText)
                    }
                }
            }
    }

    // MARK: - Suggestion Phase Methods
    private func fetchSuggestions(for query: String) async {
        print("[SearchVM] Fetching suggestions for: '\(query)'")
        isLoadingSuggestions = true

        if query != committedSearchQuery {
            searchResults = [] // Clear full results if typing a new query for suggestions
            canLoadMoreSearchResults = false
            searchResultsCurrentPage = 1
            searchResultsTotalPages = 1
        }

        do {
            let response = try await apiService.searchMovies(query: query, page: 1)
            if Task.isCancelled {
                isLoadingSuggestions = false
                return
            }
            // Limit to 5 suggestions as per new requirement
            self.searchSuggestions = Array(response.results.prefix(5))
            print("[SearchVM] Got \(self.searchSuggestions.count) suggestions for '\(query)'")
        } catch {
            if !Task.isCancelled {
                print("[SearchVM] Error fetching suggestions: \(error.localizedDescription)")
                // Don't set errorMessage here if it's just suggestions failing,
                // the main view might want to show a subtle indicator or nothing.
                // If API is down, MovieListViewModel will likely show an error too.
            }
            self.searchSuggestions = []
        }
        isLoadingSuggestions = false
    }

    // MARK: - Full Results Phase Methods
    func commitSearch(for query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            clearAllSearchData()
            return
        }

        print("[SearchVM] Committing search for: '\(trimmedQuery)'")

        // Important: Ensure searchText reflects the committed query.
        // This is especially true if a suggestion was tapped.
        // The sink will re-evaluate but due to `removeDuplicates` and potentially
        // `trimmedQuery == self.committedSearchQuery` (if it was already typed),
        // it shouldn't cause an extra API call if handled correctly.
        if self.searchText != trimmedQuery { // Update if different (e.g., tapped suggestion)
             self.searchText = trimmedQuery
        }

        self.committedSearchQuery = trimmedQuery
        self.searchSuggestions = []
        self.isLoadingSuggestions = false
        self.suggestionFetchTask?.cancel()

        await fetchFullSearchResults(isNewSearch: true)
    }

    private func fetchFullSearchResults(isNewSearch: Bool) async {
        guard !committedSearchQuery.isEmpty else { return }

        if isNewSearch {
            searchResults = []
            searchResultsCurrentPage = 1
            searchResultsTotalPages = 1
            canLoadMoreSearchResults = false
            isLoadingResults = true
            isLoadingMoreResults = false
        } else {
            guard !isLoadingMoreResults, canLoadMoreSearchResults else { return }
            isLoadingMoreResults = true
        }
        errorMessage = nil

        do {
            let response = try await apiService.searchMovies(
                query: committedSearchQuery,
                page: searchResultsCurrentPage)

            let newMovies = response.results
                .filter { newMovie in
                    !searchResults.contains(where: { $0.id == newMovie.id })
                }
            searchResults.append(contentsOf: newMovies)

            searchResultsTotalPages = response.totalPages
            if searchResultsCurrentPage < searchResultsTotalPages {
                searchResultsCurrentPage += 1
                canLoadMoreSearchResults = true
            } else {
                canLoadMoreSearchResults = false
            }
            if searchResults.isEmpty && isNewSearch {
                 print("[SearchVM] No full results found for query: '\(committedSearchQuery)'")
                 self.errorMessage = "No results found for '\(committedSearchQuery)'." // Inform user
            }
        } catch {
            let apiError = error as? APIError ?? APIError.custom("Search operation failed.")
            errorMessage = apiError.localizedDescription
            canLoadMoreSearchResults = false
        }
        if isNewSearch {
            isLoadingResults = false
        } else {
            isLoadingMoreResults = false
        }
    }

    func loadMoreFullResultsIfNeeded(currentMovieItem movie: Movie?) async {
        guard let movie = movie,
              let lastMovieId = searchResults.last?.id,
              movie.id == lastMovieId,
              canLoadMoreSearchResults,
              !isLoadingMoreResults,
              !committedSearchQuery.isEmpty else { return }
        await fetchFullSearchResults(isNewSearch: false)
    }

    // MARK: - General State Management
    func clearAllSearchData() {
        print("[SearchVM] Clearing all search data.")
        suggestionFetchTask?.cancel()
        searchSuggestions = []
        // Don't clear searchResults immediately if searchText is just being cleared,
        // let the commitSearch or new suggestion fetch handle it.
        // Only clear full results if explicitly told to or a new search starts.
        // However, if searchText becomes empty, full results should be cleared.
        if searchText.isEmpty {
            searchResults = []
            committedSearchQuery = ""
        }

        searchResultsCurrentPage = 1
        searchResultsTotalPages = 1
        canLoadMoreSearchResults = false
        isLoadingSuggestions = false
        isLoadingResults = false // If user clears search, stop loading full results.
        isLoadingMoreResults = false
        // errorMessage = nil // Let specific error messages persist until a new action.
    }
}

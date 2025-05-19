import SwiftUI

struct MovieListView: View {
    @StateObject private var movieListViewModel: MovieListViewModel = MovieListViewModel()
    @StateObject private var searchViewModel: MovieSearchViewModel = MovieSearchViewModel()

    @FocusState private var isSearchFieldFocused: Bool

    #if os(macOS)
    private let columns = [GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 20)]
    #else
    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 16)]
    #endif

    var body: some View {
        // NavigationStack should be the outermost container for navigation to work correctly.
        NavigationStack {
            VStack(spacing: 0) {
                searchBarAndSuggestions()
                // Main content area that will contain NavigationLinks
                mainContentArea
            }
            .navigationTitle(determineNavigationTitle())
            .task {
                if movieListViewModel.movies.isEmpty && searchViewModel.committedSearchQuery.isEmpty {
                    await movieListViewModel.loadInitialMovies()
                }
            }
            // Apply refreshable to a ScrollView or List inside the mainContentArea if possible,
            // or here if it's meant to refresh the whole view.
            // For this structure, applying to the overall content makes sense.
            .refreshable {
                await handleRefresh()
            }
            #if os(macOS)
            .frame(minWidth: 300, idealWidth: 700, minHeight: 400, idealHeight: 800)
            #endif
            // .navigationDestination MUST be placed on a view INSIDE the NavigationStack.
            // Placing it on the VStack containing the content is a good spot.
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movieId: movie.id, movieTitle: movie.title)
            }
        }
    }

    // Extracted main content logic into its own ViewBuilder property
    @ViewBuilder
    private var mainContentArea: some View {
        // Determine which content to show
        if !searchViewModel.committedSearchQuery.isEmpty {
            if searchViewModel.isLoadingResults && searchViewModel.searchResults.isEmpty {
                Spacer()
                LoadingIndicatorView().padding()
                Spacer()
            } else if !searchViewModel.searchResults.isEmpty {
                fullSearchResultsGrid // Display full search results
            } else if let errorMsg = searchViewModel.errorMessage {
                Spacer()
                ErrorMessageView(message: errorMsg, retryAction: {
                    Task { await searchViewModel.commitSearch(for: searchViewModel.committedSearchQuery)}
                })
                Spacer()
            } else if !searchViewModel.isLoadingResults {
                Spacer()
                ContentUnavailableView.search(text: searchViewModel.committedSearchQuery)
                Spacer()
            } else {
                Spacer()
            }
        } else {
            latestMoviesContent
        }
    }

    private func determineNavigationTitle() -> String {
        if !searchViewModel.committedSearchQuery.isEmpty {
            "Results for '\(searchViewModel.committedSearchQuery)'"
        } else if !searchViewModel.searchText.isEmpty && isSearchFieldFocused {
            "Searching..." // Or just "Search"
        } else {
            "Latest Movies"
        }
    }

    private func handleRefresh() async {
        if !searchViewModel.committedSearchQuery.isEmpty {
            await searchViewModel.commitSearch(for: searchViewModel.committedSearchQuery)
        } else {
            await movieListViewModel.refreshMovies()
        }
    }

    // MARK: - Search Bar and Suggestions Popover
    @ViewBuilder
    private func searchBarAndSuggestions() -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                TextField("Search for movies...", text: $searchViewModel.searchText)
                    .focused($isSearchFieldFocused)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task { await searchViewModel.commitSearch(for: searchViewModel.searchText) }
                        isSearchFieldFocused = false
                    }
                if !searchViewModel.searchText.isEmpty {
                    Button {
                        searchViewModel.searchText = ""
                        searchViewModel.clearAllSearchData()
                        isSearchFieldFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                    }
                }
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .background(Color(.lightGray)) // Use system color for adaptability
            .cornerRadius(10)
            .padding([.horizontal, .top])

            // Suggestions Popover
            // Display suggestions only if search field is focused AND there's text to search for
            if isSearchFieldFocused && !searchViewModel.searchText.isEmpty {
                if searchViewModel.isLoadingSuggestions && searchViewModel.searchText.count >= 2 {
                     ProgressView().padding(.vertical, 10).frame(height: 44 * 2) // Give some space for loader
                } else if !searchViewModel.searchSuggestions.isEmpty && searchViewModel.searchText.count >= 2 {
                    VStack(spacing: 0) {
                        ForEach(searchViewModel.searchSuggestions) { movie in
                            Button {
                                isSearchFieldFocused = false
                                searchViewModel.searchText = movie.title ?? "" // Update text field
                                Task { await searchViewModel.commitSearch(for: movie.title ?? "") }
                            } label: {
                                HStack {
                                    Text(movie.title ?? "N/A")
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal)
                                .frame(height: 44)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading)
                        }
                    }
                    .background(.regularMaterial)
                    .cornerRadius(10)
                    .shadow(radius: 3, x: 0, y: 2)
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    .zIndex(1)
                } else if !searchViewModel.isLoadingSuggestions &&
                            searchViewModel.searchText.count >= 2 &&
                            searchViewModel.searchSuggestions.isEmpty &&
                            searchViewModel.errorMessage == nil {
                     Text("No suggestions found.") // Only show if no other error
                        .foregroundColor(.secondary)
                        .frame(height: 44)
                        .padding(.vertical, 10)
                }
            }
            // Display the "type at least 2 characters" message from VM if applicable and search is focused
            if isSearchFieldFocused && searchViewModel.errorMessage != nil && searchViewModel.searchText.count < 2 {
                Text(searchViewModel.errorMessage!)
                   .font(.caption)
                   .foregroundColor(.orange)
                   .padding(.vertical, 5)
                   .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: searchViewModel.searchSuggestions.count)
        .animation(.easeInOut(duration: 0.15), value: isSearchFieldFocused) // Animate focus-based changes
    }

    @ViewBuilder
    private var latestMoviesContent: some View {
        ScrollView {
            if let errorMessage = movieListViewModel.errorMessage, movieListViewModel.movies.isEmpty {
                // Error view takes up space, so ScrollView might not be needed if it's the only content
                ErrorMessageView(message: errorMessage) {
                    Task { await movieListViewModel.refreshMovies() }
                }
                .padding() // Ensure it's not crunched
            } else {
                LazyVGrid(columns: columns, spacing: columns.first?.spacing ?? 16) {
                    ForEach(movieListViewModel.movies) { movie in
                        NavigationLink(value: movie) {
                            MovieCardView(movie: movie)
                                .task {
                                    if movie.id == movieListViewModel.movies.last?.id {
                                        await movieListViewModel.loadMoreMoviesIfNeeded(currentMovie: movie)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                if movieListViewModel.isLoadingPage {
                    LoadingIndicatorView().padding()
                }

                if !movieListViewModel.canLoadMorePages
                    && !movieListViewModel.movies.isEmpty
                    && movieListViewModel.errorMessage == nil {
                    Text("You've reached the end! 🎉").foregroundColor(.secondary).padding()
                }

                if let errorMessage = movieListViewModel.errorMessage,
                   !movieListViewModel.movies.isEmpty {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                    Button("Retry Failed Load") {
                        Task {
                            await movieListViewModel
                                .loadMoreMoviesIfNeeded(currentMovie: movieListViewModel.movies.last)
                        }
                    }
                    .buttonStyle(.borderless)
                    .padding(.bottom)
                }
            }
        }
    }

    @ViewBuilder
    private var fullSearchResultsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: columns.first?.spacing ?? 16) {
                ForEach(searchViewModel.searchResults) { movie in
                    NavigationLink(value: movie) {
                        MovieCardView(movie: movie)
                            .task {
                                await searchViewModel.loadMoreFullResultsIfNeeded(currentMovieItem: movie)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            if searchViewModel.isLoadingMoreResults {
                LoadingIndicatorView().padding()
            }
            if !searchViewModel.canLoadMoreSearchResults
                && !searchViewModel.searchResults.isEmpty
                && !searchViewModel.committedSearchQuery.isEmpty
                && searchViewModel.errorMessage == nil {
                Text("You've reached the end of search results! 🎬").foregroundColor(.secondary).padding()
            }
            if let errorMessage = searchViewModel.errorMessage,
               !searchViewModel.searchResults.isEmpty
                && !searchViewModel.isLoadingResults
                && !errorMessage.lowercased().contains("no results") {
                 Text("Error: \(errorMessage)")
                     .foregroundColor(.red)
                     .padding()
            }
        }
    }
}

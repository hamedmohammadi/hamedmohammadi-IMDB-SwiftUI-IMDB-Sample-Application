# TMDB Movie Browser SwiftUI App

This is a SwiftUI application for browsing movies from The Movie Database (TMDB) API. It demonstrates modern SwiftUI practices, including MVVM architecture, async/await for networking, Combine for reactive updates (especially in search), and a custom UI for displaying movie lists, details, and search functionality.

## Features

*   **Latest Movies**: Displays a list of the latest "Now Playing" movies with infinite scrolling.
*   **Movie Details**: Shows a detailed page for each movie, including poster, backdrop, overview, rating, genres, cast, and trailers (links to YouTube).
*   **Integrated Search**:
    *   Search bar integrated into the main movie list view.
    *   **Autocomplete Suggestions**: As you type (after a short debounce), a popover appears under the search bar with up to 5 movie title suggestions.
    *   **Full Search Results**: Tapping a suggestion or submitting the search query (e.g., via keyboard "Search" button) displays a full, paginated list of matching movies.
*   **Cross-Platform Design**: Built with SwiftUI, aiming for adaptability across iOS, iPadOS, and macOS.
*   **Dark Mode Support**: Adheres to system appearance.
*   **MVVM Architecture**: Clear separation of concerns between Views, ViewModels, and Models/Services.
*   **Error Handling**: Displays user-friendly error messages for network issues or failed data loading.
*   **Pull-to-Refresh**: On the movie lists.

## Requirements

*   Xcode 15.0 or later
*   Swift 5.9 or later
*   An active internet connection
*   A TMDB API v3 Bearer Token

## Setup

1.  **Install Dependencies:**
    This project is set up to use SwiftLint for code linting.
    *   **Using Homebrew:**
        ```bash
        brew install swiftlint
        ```

2.  **Configure TMDB API Key:**
    *   Open the project in Xcode.
    *   Navigate to the file `Secrets.xcconfig`.
    *   Replace the placeholder `YOUR_API_TOKEN` string for `MOVIEDB_API_TOKEN` with your actual TMDB API v3 Bearer Token:
    *   You can obtain an API key by creating an account on [themoviedb.org](https://www.themoviedb.org/signup) and requesting an API key. The Bearer Token is part of the "API Read Access Token (v4 auth)" but is used with v3 endpoints by setting the `Authorization` header to `Bearer YOUR_TOKEN`. The token provided in the prompt is used here.

3.  **Build and Run:**
    *   Select your target device or simulator in Xcode.
    *   Press `Cmd+R` or click the "Play" button to build and run the application.


## Further Improvements (Optional)

*   **Image Caching**: Implement a more robust image caching mechanism beyond `AsyncImage`'s default for better performance.
*   **Accessibility**: Enhance accessibility with more detailed labels and hints.
*   **Localization**: Add support for multiple languages.
*   **More Sophisticated State Management**: For very large apps, consider TCA (The Composable Architecture) or other advanced state management patterns.
*   **Custom Fonts and Theming**: Implement a custom visual theme.

---

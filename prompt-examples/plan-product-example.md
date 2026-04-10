### "What problem does this product solve?"

> This is an iOS app that lets users search and discover songs through the Apple iTunes Search API, listen to 30-second audio previews, and browse albums — with an offline-first experience. The core problem is giving users a fast, responsive way to find music, preview tracks, and explore album contents even when they have poor or no network connectivity.


### "Who is this product for?"

> Music fans who want a lightweight, fast song discovery app on iOS. Secondary audience: the engineering team evaluating this as a code challenge — so code quality, architecture, testability, and adherence to SOLID principles matter as much as the user experience.

### "What makes your solution unique?"

> Offline-first architecture using SwiftData cache, so recently played songs and search results are always available. Clean MVVM + SOLID architecture with a fully abstracted network layer — the API implementation is replaceable without affecting ViewModels, Views, or persistence - added as a separate Swift Package. Built entirely in Swift 6 with SwiftUI and Swift Concurrency (async/await, actors). No external dependencies — 100% native frameworks.

### "What are the must-have features for launch (MVP)?"

> **Track 1 — App Shell & Navigation:**
 Splash screen with app branding, smooth transition to Home, full navigation structure between all screens.

> **Track 2 — Network Layer:**
 Protocol-based API abstraction (the implementation must be replaceable without touching other layers). iTunes Search API client with async/await. Paginated search using limit/offset parameters. Structured error handling for network failures, empty results, and API errors.

> **Track 3 — Persistence Layer:**
SwiftData models for songs and albums. Cache strategy for search results. Recently played songs tracking and display. Offline-first logic — serve cached data when network is unavailable.

> **Track 4 — Songs Screen (Home):**
 Search bar with text input triggering API search. Paginated results list with infinite scroll. Recently played songs section (from SwiftData cache). Pull-to-refresh and loading, error, and empty states will be implemented as TODOs.

> **Track 5 — Song Details (Player):**
 Album art display and track metadata. Play/pause audio preview (30s clips via AVPlayer). Forward/backward navigation between tracks in current list. Song timeline display showing current position and duration. Player controls UI matching the Figma design.

> **Track 6 — More Options Bottom Sheet:**
Triggered from song items (home screen or elsewhere). Contextual actions for the selected song.

> **Track 7 — Album Screen:**
 Full track listing for a selected album. Navigation to Album Screen from player or search results. Album metadata display (artist, artwork, track count).

> **Note on testing:** Tests are NOT a separate module. Every module above includes tests as part of its acceptance criteria. Each module's spec will define what must be tested (ViewModel logic, network mocks, cache behavior, state transitions). The testing strategy and conventions will be documented as a standard.
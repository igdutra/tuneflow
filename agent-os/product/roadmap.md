# Product Roadmap

## Phase 1: MVP

### Track 1 — App Shell & Navigation
- Splash screen with TuneFlow branding, smooth transition to Home
- Full navigation structure between all screens

### Track 2 — Network Layer
- Protocol-based API abstraction in separate swift package
- iTunes Search API client with async/await
- Paginated search using limit/offset parameters
- Structured error handling for network failures, empty results, and API errors

### Track 3 — Persistence Layer
- SwiftData models for songs and albums
- Cache strategy for search results
- Recently played songs tracking and display
- Offline-first logic — serve cached data when network is unavailable

### Track 4 — Screen: Songs (Home)
- Search bar with text input triggering API search
- Paginated results list with infinite scroll
- Recently played songs section (from SwiftData cache)
- Pull-to-refresh - add as TODO, will be implemented later
- Loading, error, and empty states - add as TODO: will be implemented later

### Track 5 — Screen: Player (Song Detail)
- Album art display and track metadata
- Play/pause audio preview (30s clips via AVPlayer)
- Song timeline display showing current position and duration
- Player controls UI matching the Figma design

### Track 6 — More Options Bottom Sheet
- Triggered from song items (home screen or elsewhere)
- Contextual actions for the selected song

### Track 7 — Screen: Album
- Full track listing for a selected album
- Navigation to Album Screen from player or search results
- Album metadata display (artist, artwork, list all album tracks)

> **Note on testing:** Tests are NOT a separate Track. Every Track above includes tests as part of its acceptance criteria. Each Track's spec will define what must be tested (ViewModel logic, network mocks, cache behavior, state transitions). The testing strategy and conventions will be documented as a standard.

## Phase 2: Post-Launch

- Error/states handling improvements
- Swipe to refresh
- Repository organization
- Player screen enhancements:
  - Forward/backward actions
  - Slider action to seek a specific position (song timeline display is mandatory; drag-to-seek is optional)
- Accessibility

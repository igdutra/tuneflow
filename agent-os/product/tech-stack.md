# Tech Stack

## Frontend

- **Language:** Swift 6
- **UI Framework:** SwiftUI
- **Architecture:** MVVM
- **Concurrency:** Swift Concurrency (async/await, actors)
- **Audio Playback:** AVPlayer (30-second previews)

## Backend

N/A — client-only app consuming a public API.

- **API:** [iTunes Search API](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/Searching.html#//apple_ref/doc/uid/TP40017632-CH5-SW1)
- **Network Layer:** Protocol-based abstraction, packaged as a separate Swift Package. The API implementation is replaceable without affecting other layers.
- **Pagination:** Limit/offset parameters on search requests

## Database

- **SwiftData** — used for offline-first caching of search results and recently played songs

## Other

- No external dependencies — 100% native Apple frameworks
- Tests included as part of every module's acceptance criteria

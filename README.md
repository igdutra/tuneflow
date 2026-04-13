# TuneFlow

[![CI](https://github.com/igdutra/tuneflow/actions/workflows/ci.yml/badge.svg)](https://github.com/igdutra/tuneflow/actions/workflows/ci.yml)

TuneFlow is a SwiftUI music discovery app for searching songs, exploring albums, and previewing tracks with the iTunes Search API.

This project is built with a spec-driven development workflow using AgentOS V3, emphasizing clean architecture, testability, and an offline-first user experience.

## Tech Stack

- Swift 6
- SwiftUI
- MVVM
- Swift Concurrency
- SwiftData
- Pagination
- Unit tests

## Features

- Search songs via iTunes Search API
- Browse album details
- Preview tracks in a player flow
- Cache recently played songs for offline-first UX

## Running Tests

### App tests (requires simulator)

Run all TuneFlow app tests:
```bash
 xcodebuild clean build test -scheme TuneFlow -destination 'platform=iOS Simulator,name=iPhone 17' -testPlan "TuneFlowTestPlan"
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
```

### Package tests (no simulator needed)

Tests live in `Packages/TuneAPI`. There are two test targets:

| Target | What it tests |
|--------|---------------|
| `TuneAPITests` | Unit tests — no network, runs fast |
| `TuneAPIIntegrationTests` | Integration tests — hits the real iTunes API |

Run unit tests:
```bash
swift test --package-path Packages/TuneAPI --filter TuneAPITests
```

Run integration tests:
```bash
swift test --package-path Packages/TuneAPI --filter TuneAPIIntegrationTests
```

Run both:
```bash
swift test --package-path Packages/TuneAPI
```

## Custom /agent-os/shape-spec command

Shape-spec command was altered. Keeps the same shaping flow but adds stricter execution guidance: it makes the commit expectation more explicit after successful task implementation, and it clarifies that all tasks should be implemented against their acceptance criteria first, with behavior testing happening afterward in the same plan, covering both the primary case and the relevant error cases.

### Custom Font

Original Mockups used Articulat CF - DemiBold and Medium. We are not buying  for this project. The implementation should use native **SF** fonts for now. This is an execution tradeoff, not a design change: the typography layer can be swapped later with minimal code changes by replacing the font mappings in one place.
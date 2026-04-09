# TuneFlow

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

## Custom /agent-os/shape-spec command

Shape-spec command was altered. Keeps the same shaping flow but adds stricter execution guidance: it makes the commit expectation more explicit after successful task implementation, and it clarifies that all tasks should be implemented against their acceptance criteria first, with behavior testing happening afterward in the same plan, covering both the primary case and the relevant error cases.
# Product Mission

## Problem

Users need a fast, responsive way to find music, preview tracks, and explore album contents even when they have poor or no network connectivity. Existing solutions don't prioritize offline-first experiences for music discovery on iOS.

## Target Users

- **Primary:** Music fans who want a lightweight, fast song discovery app on iOS.
- **Secondary:** Engineering teams evaluating this as a code challenge — code quality, architecture, testability, and adherence to SOLID principles matter as much as the user experience.

## Solution

TuneFlow is an iOS app that lets users search and discover songs through the Apple iTunes Search API, listen to 30-second audio previews, and browse albums — with an offline-first experience.

Key differentiators:

- **Offline-first architecture** using SwiftData cache, so recently played songs and search results are always available.
- **Clean MVVM + SOLID architecture** with a fully abstracted network layer — the API implementation is replaceable without affecting ViewModels, Views, or persistence. The network layer is added as a separate Swift Package.
- **Built entirely in Swift 6** with SwiftUI and Swift Concurrency (async/await, actors).
- **No external dependencies** — 100% native frameworks.

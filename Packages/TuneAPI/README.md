# TuneAPI

`TuneAPI` is the shared API package for TuneFlow. The goal is to keep networking, request building, response models, and related API code outside the app target so the same module can be reused by both iOS and macOS applications.

Separating the API into its own package improves composition and modularity by giving the project a clean boundary around backend communication. It also gives much faster feedback during development, because package unit tests can be run directly on macOS from Xcode or the command line instead of waiting on the iOS Simulator. The package is meant to be a portable, testable foundation for any TuneFlow client.

This could also be modeled as an internal framework. Keeping it as a local Swift package is often a good fit when you want a single place to manage dependencies and a lightweight way to share code across targets, but the right choice depends on the project and the specific use case.

## Run Tests From The CLI

From the package directory:

```bash
cd Packages/TuneAPI
swift test
```

From the project root:

```bash
swift test --package-path Packages/TuneAPI
```

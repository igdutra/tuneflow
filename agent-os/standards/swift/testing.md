# Swift Testing Standard

Use `Swift Testing` for all unit tests. Never mix with `XCTest` assertions.

## Core Rules

- `import Testing` only in test targets
- `@Test` on every test function
- `struct` suites by default; `class` only when teardown or reference semantics are truly needed
- One behavior per test
- Tests must be parallel-safe and order-independent
- No `@MainActor` unless the code under test requires main-thread isolation
- No `Task.sleep(...)` for synchronization

## SUT Construction

Always use `makeSUT()` returning a typed tuple with the SUT and all doubles:

```swift
private extension SearchSongsUseCaseTests {
    typealias SUTBundle = (
        sut: SearchSongsUseCase,
        repositorySpy: SongRepositorySpy,
        loggerSpy: LoggerSpy
    )

    func makeSUT(source: SourceLocation = #_sourceLocation) -> SUTBundle {
        let repositorySpy = SongRepositorySpy()
        let loggerSpy = LoggerSpy()
        let sut = SearchSongsUseCase(repository: repositorySpy, logger: loggerSpy)
        _ = source  // reserved for leak tracking hookup
        return (sut, repositorySpy, loggerSpy)
    }
}
```

- All doubles created in one place
- Each test gets fresh state — no hidden mutable suite properties
- Dependencies visible at the call site
- `source: SourceLocation = #_sourceLocation` is reserved for future leak tracking; keep it in `makeSUT()` even if unused today

## Test Doubles: Spy vs Stub

Use the right double for the job:

**Spy (class)** — records calls AND can be stubbed. Use when the test needs to verify interactions:

```swift
final class SongRepositorySpy: SongRepository {
    // Stubbing
    var stubbedSearchResult: Result<[Song], Error> = .success([])
    var stubbedAlbumResult: Result<[Song], Error> = .success([])

    // Recorded calls
    private(set) var searchCallCount = 0
    private(set) var searchCalledWithQuery: String?
    private(set) var searchCalledWithLimit: Int?
    private(set) var searchCalledWithOffset: Int?

    func search(query: String, limit: Int, offset: Int) async throws -> [Song] {
        searchCallCount += 1
        searchCalledWithQuery = query
        searchCalledWithLimit = limit
        searchCalledWithOffset = offset
        return try stubbedSearchResult.get()
    }

    func stub(result: [Song]) {
        stubbedSearchResult = .success(result)
    }

    func stub(error: Error) {
        stubbedSearchResult = .failure(error)
    }
}
```

**Stub (struct)** — returns a fixed value. Use when the test only needs to control what a dependency returns, not verify it was called:

```swift
struct SongRepositoryStub: SongRepository {
    let result: [Song]

    func search(query: String, limit: Int, offset: Int) async throws -> [Song] {
        result
    }

    func fetchAlbum(collectionId: Int) async throws -> [Song] {
        result
    }
}
```

Choose the simplest double that makes the test pass. A spy that records everything but the test never checks is noise.

## Assertions

- `#expect` — default for equality, booleans, counts
- `#require` — when later lines depend on a value (replaces `try XCTUnwrap`)
- `#expect(throws:)` — when only the throw matters
- `#require(throws:)` — when the thrown value must be inspected afterward
- `Issue.record(...)` — only for control paths that can't be expressed otherwise

```swift
#expect(result == expected)
#expect(repositorySpy.searchCallCount == 1)
#expect(repositorySpy.searchCalledWithQuery == "Beatles")
let song = try #require(result.first)

await #expect(throws: SongError.notFound) {
    try await sut.execute(query: "")
}

let thrownError = try await #require(throws: SongError.self) {
    try await sut.execute(query: "")
}
#expect(thrownError == .notFound)
```

## Test Naming

- No `test...` prefix
- Describe behavior: `execute_onSuccess_returnsSearchResults`
- Format: `subject_condition_expectedOutcome`
- Use display names (`.displayName`) only when the function name would be unreadable — e.g., for parameterized cases:

```swift
@Test("search with empty query returns cached results", arguments: [...])
```

## Parameterized Tests

Default for one behavior with multiple input cases:

```swift
@Test(arguments: [
    (SongError.notFound, "Song not found"),
    (SongError.networkUnavailable, "Network unavailable")
])
func execute_onError_logsExpectedMessage(
    error: SongError,
    expectedMessage: String
) async throws {
    let (sut, repositorySpy, loggerSpy) = makeSUT()
    repositorySpy.stub(error: error)

    let thrownError = try await #require(throws: SongError.self) {
        try await sut.execute(query: "Beatles")
    }

    let firstLog = try #require(loggerSpy.messages.first)
    guard case let .error(message) = firstLog else {
        Issue.record("Expected error log")
        return
    }

    #expect(thrownError == error)
    #expect(loggerSpy.messages.count == 1)
    #expect(message == expectedMessage)
}
```

Rules:
- Inline arguments unless genuinely reused
- Concrete expected values — never derived from the same logic as production code
- No `if`/`switch` branching inside a parameterized body
- Prefer tuples over `zip(allCases, allCases)`

## Suite Template

```swift
import Testing
@testable import TuneFlow

struct SearchSongsUseCaseTests {
    @Test func execute_onSuccess_returnsSearchResults() async throws {
        let (sut, repositorySpy, _) = makeSUT()
        repositorySpy.stub(result: [Song.fixture])

        let result = try await sut.execute(query: "Beatles")

        #expect(result == [Song.fixture])
        #expect(repositorySpy.searchCallCount == 1)
        #expect(repositorySpy.searchCalledWithQuery == "Beatles")
    }

    @Test func execute_onFailure_throwsAndLogsError() async throws {
        let (sut, repositorySpy, loggerSpy) = makeSUT()
        repositorySpy.stub(error: SongError.notFound)

        await #expect(throws: SongError.notFound) {
            try await sut.execute(query: "Beatles")
        }
        #expect(loggerSpy.messages.count == 1)
    }
}

private extension SearchSongsUseCaseTests {
    typealias SUTBundle = (
        sut: SearchSongsUseCase,
        repositorySpy: SongRepositorySpy,
        loggerSpy: LoggerSpy
    )

    func makeSUT(source: SourceLocation = #_sourceLocation) -> SUTBundle {
        let repositorySpy = SongRepositorySpy()
        let loggerSpy = LoggerSpy()
        let sut = SearchSongsUseCase(repository: repositorySpy, logger: loggerSpy)
        _ = source
        return (sut, repositorySpy, loggerSpy)
    }
}
```

## Async Testing

- Mark tests `async` when the production API is async
- Stub before invoking the SUT
- Use deterministic stubs — no live network, no real timers
- Bridge callback APIs with continuations
- Use `confirmation(...)` for event-style async behavior

Avoid:
- `Task.sleep(...)` as the main synchronization strategy
- Returning from the test before async work completes
- Shared mutable counters in callback tests unless isolation-safe

## `@MainActor`

Do not mark a suite or test `@MainActor` by default.

Use it only when:
- The code under test is `@MainActor` (e.g., a view model)
- The API requires main-thread isolation

Pure use cases, repositories, mappers, and cache loaders should stay off the main actor.

```swift
// View model tests need @MainActor because the VM is @MainActor @Observable
@MainActor
struct SongsViewModelTests {
    @Test func load_onSuccess_populatesViewData() async {
        let (sut, repositorySpy) = makeSUT()
        repositorySpy.stub(result: [Song.fixture])

        await sut.load()

        #expect(sut.state.value != nil)
        #expect(sut.viewData != nil)
    }
}
```

## Isolation and Parallel Execution

Swift Testing runs tests in parallel with randomized order.

- Create fresh state per test — no shared mutable state
- Avoid mutable globals and mutable singletons
- Prefer in-memory stubs and fakes
- Use `.serialized` only as a narrow transitional tool — document why and plan to remove it

## Traits, Tags, and Availability

- `.disabled("reason")` instead of commenting tests out
- `.bug(...)` for known failures when possible
- `withKnownIssue(...)` to keep a failing test visible in reports without blocking CI
- Tags for cross-cutting filtering: `core`, `integration`, `regression`
- Apply tags at suite level when they apply to all tests
- `@available` on individual tests, not suite types

## Review Checklist

Before merging a test suite:

- [ ] Uses `Swift Testing`, not `XCTest`
- [ ] `struct` suite unless documented otherwise
- [ ] `makeSUT()` centralizes setup and returns typed tuple
- [ ] Dependencies stubbed before the action under test
- [ ] `#expect` is the default assertion
- [ ] `#require` used for prerequisites and captured throws
- [ ] Repeated cases are parameterized
- [ ] Expected values are concrete and readable
- [ ] Suite is parallel-safe
- [ ] `@MainActor` only when the SUT requires it
- [ ] Disabled tests have reasons (`.disabled` or `withKnownIssue`)
- [ ] Spies record calls; stubs return fixed values — right tool chosen

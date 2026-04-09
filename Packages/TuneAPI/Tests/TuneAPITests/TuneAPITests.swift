import Testing
@testable import TuneAPI

struct TuneRepositoryImpl: TuneRepository {
    func fetchTunes() async throws -> [String] {
        [""]
    }
}

@Test func example() async throws {
    let tune1 = TuneRepositoryImpl()
    try await #expect(tune1.fetchTunes().first == "")
}

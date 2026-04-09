// The Swift Programming Language
// https://docs.swift.org/swift-book

public protocol TuneRepository {
    func fetchTunes() async throws -> [String]
}

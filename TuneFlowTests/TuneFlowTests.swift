//
//  TuneFlowTests.swift
//  TuneFlowTests
//
//  Created by Ivo on 09/04/26.
//

import Testing
@testable import TuneFlow
import TuneAPI

struct TuneAPIStub: TuneRepository {
    func fetchTunes() async throws -> [String] {
        ["This is a stub"]
    }
}

struct TuneFlowTests {

    @Test func example() async throws {
        let spy = TuneAPIStub()
        try await #expect(spy.fetchTunes().first == "This is a stub")
    }
}

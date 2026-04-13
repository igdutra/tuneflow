import Testing
@testable import TuneFlow
internal import SwiftUI

@MainActor
struct AppRouterTests {

    // MARK: - Initial State

    @Test func init_startsWithEmptyPathAndNilSheet() {
        let sut = makeSUT()

        #expect(sut.path.count == 0)
        #expect(sut.sheet == nil)
    }

    // MARK: - Push

    @Test func push_appendsRouteToPath() {
        let sut = makeSUT()

        sut.push(.player(.fixture(), queue: [], currentIndex: 0))

        #expect(sut.path.count == 1)
    }

    @Test func push_multipleTimes_appendsEachRoute() {
        let sut = makeSUT()

        sut.push(.player(.fixture(id: 1), queue: [], currentIndex: 0))
        sut.push(.player(.fixture(id: 2), queue: [], currentIndex: 0))

        #expect(sut.path.count == 2)
    }

    // MARK: - Pop

    @Test func pop_removesLastRoute() {
        let sut = makeSUT()
        sut.push(.player(.fixture(), queue: [], currentIndex: 0))

        sut.pop()

        #expect(sut.path.count == 0)
    }

    @Test func pop_whenPathIsEmpty_doesNotCrash() {
        let sut = makeSUT()

        sut.pop()

        #expect(sut.path.count == 0)
    }

    // MARK: - Pop to Root

    @Test func popToRoot_clearsAllRoutes() {
        let sut = makeSUT()
        sut.push(.player(.fixture(id: 1), queue: [], currentIndex: 0))
        sut.push(.player(.fixture(id: 2), queue: [], currentIndex: 1))
        sut.push(.player(.fixture(id: 3), queue: [], currentIndex: 2))

        sut.popToRoot()

        #expect(sut.path.count == 0)
    }

    // MARK: - Album Route

    @Test func push_albumRoute_appendsToPath() {
        let sut = makeSUT()

        sut.push(.album(collectionId: 42))

        #expect(sut.path.count == 1)
    }

    // MARK: - Sheet

    @Test func present_setsSheet() {
        let sut = makeSUT()

        sut.present(.moreOptions(.fixture()))

        #expect(sut.sheet != nil)
    }

    @Test func dismissSheet_clearsSheet() {
        let sut = makeSUT()
        sut.present(.moreOptions(.fixture()))

        sut.dismissSheet()

        #expect(sut.sheet == nil)
    }
}

// MARK: - Helpers

private extension AppRouterTests {
    func makeSUT(source: SourceLocation = #_sourceLocation) -> AppRouter {
        _ = source
        return AppRouter()
    }
}

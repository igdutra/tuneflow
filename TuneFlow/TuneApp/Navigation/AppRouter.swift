import SwiftUI

@MainActor
@Observable
final class AppRouter {

    // MARK: - Navigation State

    var path = NavigationPath()
    var sheet: AppSheet?

    // MARK: - Push

    func push(_ route: AppRoute) {
        path.append(route)
    }

    // MARK: - Pop

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    // MARK: - Sheets

    func present(_ sheet: AppSheet) {
        self.sheet = sheet
    }

    func dismissSheet() {
        sheet = nil
    }
}

import Foundation

enum ViewState: Sendable {
    case idle
    case loading
    case loaded
    case error(any Error & Sendable)
}

extension ViewState {
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }

    var error: (any Error)? {
        if case .error(let error) = self { return error }
        return nil
    }
}

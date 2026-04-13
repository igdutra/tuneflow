import Foundation

enum ViewState: Sendable {
    case idle
    case loading
    case loaded
    case error
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

    var hasError: Bool {
        if case .error = self { return true }
        return false
    }
}

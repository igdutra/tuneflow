@testable import TuneFlow

extension ViewState: @retroactive Equatable {
    public static func == (lhs: ViewState, rhs: ViewState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.loading, .loading): return true
        case (.loaded, .loaded): return true
        case (.error, .error): return true
        default: return false
        }
    }
}

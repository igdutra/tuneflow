import SwiftUI

// Apply state-driven overlays rather than replacing the root view with if/switch.
//
// Overlays preserve the identity of the parent view across state transitions —
// SwiftUI never tears down and recreates the content, so scroll position and
// internal view state survive loading → loaded and loaded → error transitions.
//
// This follows the overlay pattern recommended in "Demystify SwiftUI" (WWDC21)
// and the ContentUnavailableView guidance in the Apple documentation:
// https://developer.apple.com/documentation/swiftui/contentunavailableview
//
//   List { … }
//   .overlay {                          // ← overlay, NOT if/else around List
//       if results.isEmpty {
//           ContentUnavailableView.search
//       }
//   }
//
// The List stays in the hierarchy at all times; only the overlay layer changes.
// Replacing the root view (if isLoading { Spinner() } else { List { … } })
// would give the two branches different identities, forcing SwiftUI to destroy
// and remount the full subtree on every transition.

extension View {
    func stateOverlay(
        state: ViewState,
        errorTitle: String? = nil,
        errorMessage: String? = nil,
        errorAction: ErrorView.Action? = nil
    ) -> some View {
        self
            .opacity(state.isLoading || state.error != nil ? 0 : 1)
            .disabled(state.isLoading || state.error != nil)
            .overlay {
                if state.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                } else if state.error != nil {
                    ErrorView(
                        title: errorTitle,
                        message: errorMessage,
                        action: errorAction
                    )
                }
            }
    }
}

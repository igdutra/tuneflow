import SwiftUI

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

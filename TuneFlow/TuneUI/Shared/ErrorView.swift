import SwiftUI

struct ErrorView: View {
    struct Action {
        let title: String
        let handler: () -> Void
    }

    let title: String?
    let message: String?
    let action: Action?

    init(
        title: String? = "Something went wrong",
        message: String? = nil,
        action: Action? = nil
    ) {
        self.title = title
        self.message = message
        self.action = action
    }

    var body: some View {
        VStack(spacing: 12) {
            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }

            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let action {
                Button(action.title, action: action.handler)
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

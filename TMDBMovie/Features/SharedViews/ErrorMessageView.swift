import SwiftUI

struct ErrorMessageView: View {
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            if let retryAction = retryAction {
                Button("Retry", action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Center it
        .background(.regularMaterial)
    }
}

struct ErrorMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorMessageView(message: "Could not load movies. Please check your connection.",
                         retryAction: { print("Retry tapped") })
            .previewLayout(.sizeThatFits)

        ErrorMessageView(message: "A network error occurred.", retryAction: nil)
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
    }
}

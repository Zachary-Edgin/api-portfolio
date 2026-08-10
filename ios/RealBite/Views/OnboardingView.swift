import SwiftUI
import UIKit

/// A calm, minimal location-permission gate. Doubles as the "enable in Settings"
/// screen when access was previously denied.
struct OnboardingView: View {
    @ObservedObject var viewModel: RestaurantListViewModel

    private var isDenied: Bool {
        viewModel.authorizationStatus == .denied || viewModel.authorizationStatus == .restricted
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.accentColor.opacity(0.12))
                .frame(width: 84, height: 84)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 34, weight: .regular))
                        .foregroundStyle(Color.accentColor)
                )

            Text("RealBite")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .padding(.top, 20)

            Text("Order directly from local restaurants.\nReal prices. Pickup only.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: primaryAction) {
                Text(isDenied ? "Open Settings" : "Find restaurants near me")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)

            Text(isDenied
                 ? "Location is off. Enable it in Settings to search nearby."
                 : "We use your location only to show nearby restaurants.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 14)
                .padding(.bottom, 28)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private func primaryAction() {
        if isDenied {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } else {
            viewModel.locationManager.requestLocation()
        }
    }
}

#Preview {
    OnboardingView(viewModel: RestaurantListViewModel())
}

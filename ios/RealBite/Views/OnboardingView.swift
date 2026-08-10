import SwiftUI
import UIKit

/// Location-permission gate and brand moment. Doubles as the "enable in Settings"
/// screen when access was previously denied.
struct OnboardingView: View {
    @ObservedObject var viewModel: RestaurantListViewModel

    private var isDenied: Bool {
        viewModel.authorizationStatus == .denied || viewModel.authorizationStatus == .restricted
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0xFF7E5F), Color(hex: 0xE6734C), Color(hex: 0xC2410C)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient blurred glow
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -120, y: -220)

            VStack(spacing: 0) {
                Spacer()

                brandMark
                    .padding(.bottom, 22)

                Text("RealBite")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Order direct. Real prices.\nPickup only.")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 14) {
                    ValueRow(icon: "mappin.and.ellipse", text: "Find restaurants right around you")
                    ValueRow(icon: "arrow.up.right.circle.fill", text: "Order from their own website")
                    ValueRow(icon: "tag.fill", text: "No delivery-app markup or fees")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 36)

                VStack(spacing: 12) {
                    Button(action: primaryAction) {
                        Text(isDenied ? "Open Settings" : "Find restaurants near me")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(Color(hex: 0xC2410C))
                    }

                    Text(isDenied
                         ? "Location is off. Enable it in Settings to search nearby."
                         : "We use your location only to show nearby restaurants.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }

    private var brandMark: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(.white.opacity(0.16))
            .frame(width: 104, height: 104)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.35), lineWidth: 1)
            )
            .overlay(
                Image(systemName: "fork.knife")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(.white)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
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

private struct ValueRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.16), in: Circle())
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(viewModel: RestaurantListViewModel())
}

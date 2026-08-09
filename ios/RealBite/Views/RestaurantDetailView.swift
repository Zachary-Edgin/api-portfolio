import SwiftUI
import MapKit

/// Restaurant detail with the primary call-to-action: order directly from the
/// restaurant's own website for pickup. Also offers directions and a phone call.
struct RestaurantDetailView: View {
    let restaurant: Restaurant

    @State private var orderDestination: OrderDestination?
    @State private var showingNoWebsiteFallback = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                mapSnapshot
                actions
                infoRows
                valueNote
            }
            .padding()
        }
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .sheet(item: $orderDestination) { destination in
            SafariView(url: destination.url)
                .ignoresSafeArea()
        }
        .confirmationDialog(
            "This restaurant hasn't listed an online ordering page.",
            isPresented: $showingNoWebsiteFallback,
            titleVisibility: .visible
        ) {
            Button("Search the web for their menu") {
                if let webSearchURL { orderDestination = OrderDestination(url: webSearchURL) }
            }
            if restaurant.phoneNumber != nil {
                Button("Call to order") { callRestaurant() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can search for their site or call the restaurant to order for pickup.")
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let category = restaurant.category {
                Text(category.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(restaurant.name)
                .font(.title.weight(.bold))
            HStack(spacing: 10) {
                if let distance = restaurant.distanceDescription {
                    Label(distance, systemImage: "location.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Label("Pickup", systemImage: "bag.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var mapSnapshot: some View {
        Map(initialPosition: .region(region), interactionModes: []) {
            Marker(restaurant.name, systemImage: "fork.knife", coordinate: restaurant.coordinate)
                .tint(.accentColor)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .allowsHitTesting(false)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button(action: orderDirect) {
                Label("Order for Pickup", systemImage: "bag.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            HStack(spacing: 12) {
                Button(action: openDirections) {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(action: callRestaurant) {
                    Label("Call", systemImage: "phone.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(restaurant.phoneNumber == nil)
            }
        }
    }

    @ViewBuilder
    private var infoRows: some View {
        VStack(spacing: 0) {
            if let address = restaurant.address {
                InfoRow(icon: "mappin.and.ellipse", text: address)
                Divider().padding(.leading, 44)
            }
            if let phone = restaurant.phoneNumber {
                InfoRow(icon: "phone.fill", text: phone)
                Divider().padding(.leading, 44)
            }
            if let website = restaurant.website {
                InfoRow(icon: "globe", text: website.host ?? website.absoluteString)
            }
        }
        .padding(.vertical, 4)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var valueNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(Color.green)
            Text("Ordering here goes straight to the restaurant — no delivery-app commissions or service fees added to your total.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Actions

    private func orderDirect() {
        if let website = restaurant.website {
            orderDestination = OrderDestination(url: website)
        } else {
            showingNoWebsiteFallback = true
        }
    }

    private func openDirections() {
        let placemark = MKPlacemark(coordinate: restaurant.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = restaurant.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func callRestaurant() {
        guard
            let phone = restaurant.phoneNumber,
            let url = URL(string: "tel://\(phone.filter { $0.isNumber || $0 == "+" })")
        else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Helpers

    private var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: restaurant.coordinate,
            latitudinalMeters: 400,
            longitudinalMeters: 400
        )
    }

    private var webSearchURL: URL? {
        let terms = "\(restaurant.name) \(restaurant.address ?? "") order online pickup"
        let query = terms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://duckduckgo.com/?q=\(query)")
    }
}

private struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

/// Identifiable wrapper so a URL can drive `.sheet(item:)`.
private struct OrderDestination: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

#Preview {
    NavigationStack {
        RestaurantDetailView(restaurant: Restaurant.previewList[0])
    }
}

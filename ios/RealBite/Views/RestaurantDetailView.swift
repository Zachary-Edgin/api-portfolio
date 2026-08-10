import SwiftUI
import MapKit

/// Restaurant detail: a hero cover, quick actions, details, and a sticky
/// "Order for Pickup" bar that hands the user to the restaurant's own site.
struct RestaurantDetailView: View {
    let restaurant: Restaurant

    @State private var orderDestination: OrderDestination?
    @State private var showingNoWebsiteFallback = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                quickActions
                infoCard
                locationCard
                valueNote
            }
            .padding(16)
            .padding(.bottom, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteButton(restaurant: restaurant, glass: false)
            }
        }
        .safeAreaInset(edge: .bottom) { orderBar }
        .sheet(item: $orderDestination) { destination in
            SafariView(url: destination.url).ignoresSafeArea()
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

    // MARK: - Hero

    private var hero: some View {
        CoverArtView(restaurant: restaurant, glyphSize: 64)
            .frame(height: 210)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    if let category = restaurant.category {
                        Text(category.uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Text(restaurant.name)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        if let distance = restaurant.distanceDescription {
                            Label(distance, systemImage: "location.fill")
                        }
                        Label("Pickup", systemImage: "bag.fill")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                }
                .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        HStack(spacing: 10) {
            QuickAction(icon: "arrow.triangle.turn.up.right.diamond.fill", label: "Directions", action: openDirections)
            QuickAction(icon: "phone.fill", label: "Call", action: callRestaurant, disabled: restaurant.phoneNumber == nil)
            QuickAction(icon: "globe", label: "Website", action: openWebsite, disabled: restaurant.website == nil)
        }
    }

    // MARK: - Info

    private var infoCard: some View {
        VStack(spacing: 0) {
            if let address = restaurant.address {
                InfoRow(icon: "mappin.and.ellipse", text: address)
            }
            if let phone = restaurant.phoneNumber {
                if restaurant.address != nil { Divider().padding(.leading, 46) }
                InfoRow(icon: "phone.fill", text: phone)
            }
            if let website = restaurant.website {
                if restaurant.address != nil || restaurant.phoneNumber != nil { Divider().padding(.leading, 46) }
                InfoRow(icon: "globe", text: website.host ?? website.absoluteString)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var locationCard: some View {
        Map(initialPosition: .region(region), interactionModes: []) {
            Annotation(restaurant.name, coordinate: restaurant.coordinate) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.accentColor)
                    .background(Circle().fill(.white).padding(3))
            }
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .allowsHitTesting(false)
    }

    private var valueNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
            Text("Ordering here goes straight to the restaurant — no delivery-app commissions or service fees added to your total.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Sticky order bar

    private var orderBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: orderDirect) {
                Label("Order for Pickup", systemImage: "bag.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)
        }
        .background(.bar)
    }

    // MARK: - Actions

    private func orderDirect() {
        if let website = restaurant.website {
            orderDestination = OrderDestination(url: website)
        } else {
            showingNoWebsiteFallback = true
        }
    }

    private func openWebsite() {
        if let website = restaurant.website { orderDestination = OrderDestination(url: website) }
    }

    private func openDirections() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: restaurant.coordinate))
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
        MKCoordinateRegion(center: restaurant.coordinate, latitudinalMeters: 400, longitudinalMeters: 400)
    }

    private var webSearchURL: URL? {
        let terms = "\(restaurant.name) \(restaurant.address ?? "") order online pickup"
        let query = terms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://duckduckgo.com/?q=\(query)")
    }
}

// MARK: - Subviews

private struct QuickAction: View {
    let icon: String
    let label: String
    let action: () -> Void
    var disabled: Bool = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                Text(label).font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(disabled ? Color.secondary : Color.accentColor)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

private struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
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
    .environmentObject(FavoritesStore())
}

import SwiftUI
import MapKit

/// A calm restaurant detail: title, a clean map, a few quiet actions, and one
/// clear primary action — order directly from the restaurant's own site for pickup.
struct RestaurantDetailView: View {
    let restaurant: Restaurant

    @State private var orderDestination: OrderDestination?
    @State private var showingNoWebsiteFallback = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                mapCard
                actions
                details
                valueLine
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteButton(restaurant: restaurant)
            }
        }
        .safeAreaInset(edge: .bottom) { orderBar }
        .sheet(item: $orderDestination) { destination in
            SafariView(url: destination.url).ignoresSafeArea()
        }
        .confirmationDialog(
            "This restaurant hasn’t listed an online ordering page.",
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

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(restaurant.name)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
            if !restaurant.metaLine.isEmpty {
                Text(restaurant.metaLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var mapCard: some View {
        Map(initialPosition: .region(region), interactionModes: []) {
            Annotation("", coordinate: restaurant.coordinate) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor, Color(.systemBackground))
            }
            .annotationTitles(.hidden)
        }
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .allowsHitTesting(false)
    }

    // MARK: - Actions

    private var actions: some View {
        HStack(spacing: 0) {
            SecondaryAction(icon: "arrow.triangle.turn.up.right.diamond", label: "Directions", action: openDirections)
            SecondaryAction(icon: "phone", label: "Call", action: callRestaurant, disabled: restaurant.phoneNumber == nil)
            SecondaryAction(icon: "safari", label: "Website", action: openWebsite, disabled: restaurant.website == nil)
        }
    }

    // MARK: - Details

    private var details: some View {
        VStack(spacing: 0) {
            if let address = restaurant.address {
                DetailRow(label: "Address", value: address)
            }
            if let phone = restaurant.phoneNumber {
                DetailRow(label: "Phone", value: phone)
            }
            if let hours = restaurant.openingHours {
                DetailRow(label: "Hours", value: hours)
            }
            if let website = restaurant.website {
                DetailRow(label: "Website", value: website.host ?? website.absoluteString)
            }
        }
    }

    private var valueLine: some View {
        Label {
            Text("Direct from the restaurant — no delivery-app fees added.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "checkmark.seal")
                .font(.footnote)
                .foregroundStyle(Color.accentColor)
        }
        .labelStyle(.titleAndIcon)
    }

    // MARK: - Sticky order bar

    private var orderBar: some View {
        Button(action: orderDirect) {
            Text("Order for Pickup")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }

    // MARK: - Actions logic

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
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private func callRestaurant() {
        guard
            let phone = restaurant.phoneNumber,
            let url = URL(string: "tel://\(phone.filter { $0.isNumber || $0 == "+" })")
        else { return }
        UIApplication.shared.open(url)
    }

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

private struct SecondaryAction: View {
    let icon: String
    let label: String
    let action: () -> Void
    var disabled: Bool = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 20, weight: .regular))
                Text(label).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(disabled ? Color.secondary : Color.accentColor)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 68, alignment: .leading)
                Text(value)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 12)
            Divider().overlay(Color.primary.opacity(0.06))
        }
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

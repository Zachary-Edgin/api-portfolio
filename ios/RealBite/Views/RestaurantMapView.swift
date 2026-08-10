import SwiftUI
import MapKit

/// The "Map" tab: nearby restaurants as clean dots with a single card for the
/// selected place. Tap a dot to preview it, tap the card to open it.
struct RestaurantMapView: View {
    @ObservedObject var viewModel: RestaurantListViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selected: Restaurant?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                map
                if let selected {
                    SelectedCard(restaurant: selected)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Restaurant.self) { restaurant in
                RestaurantDetailView(restaurant: restaurant)
            }
            .animation(.spring(duration: 0.3), value: selected)
            .onAppear {
                viewModel.start()
                if selected == nil { selected = viewModel.restaurants.first }
                fitCamera(to: viewModel.restaurants)
            }
            .onChange(of: viewModel.restaurants) { _, restaurants in
                selected = restaurants.first
                fitCamera(to: restaurants)
            }
        }
    }

    private var map: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            ForEach(viewModel.restaurants) { restaurant in
                Annotation(restaurant.name, coordinate: restaurant.coordinate) {
                    MapDot(isSelected: selected == restaurant)
                        .onTapGesture { selected = restaurant }
                }
                .annotationTitles(.hidden)
            }
        }
        .mapControls { MapUserLocationButton() }
        .ignoresSafeArea(edges: .top)
    }

    private func fitCamera(to restaurants: [Restaurant]) {
        guard !restaurants.isEmpty else { return }
        let coords = restaurants.map(\.coordinate)
        let lats = coords.map(\.latitude), lons = coords.map(\.longitude)
        guard
            let minLat = lats.min(), let maxLat = lats.max(),
            let minLon = lons.min(), let maxLon = lons.max()
        else { return }

        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.012),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.012)
        )
        withAnimation(.easeInOut) {
            cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }
}

// MARK: - Pin

private struct MapDot: View {
    let isSelected: Bool

    var body: some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: isSelected ? 20 : 13, height: isSelected ? 20 : 13)
            .overlay(Circle().stroke(Color(.systemBackground), lineWidth: isSelected ? 3 : 2))
            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
    }
}

// MARK: - Selected card

private struct SelectedCard: View {
    let restaurant: Restaurant

    var body: some View {
        NavigationLink(value: restaurant) {
            HStack(spacing: 14) {
                Thumbnail(restaurant: restaurant, size: 48)
                VStack(alignment: .leading, spacing: 3) {
                    Text(restaurant.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if !restaurant.metaLine.isEmpty {
                        Text(restaurant.metaLine)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RestaurantMapView(viewModel: RestaurantListViewModel())
        .environmentObject(FavoritesStore())
}

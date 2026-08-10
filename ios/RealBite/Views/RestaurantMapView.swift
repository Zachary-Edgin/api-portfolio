import SwiftUI
import MapKit

/// The "Map" tab: nearby restaurants as custom pins with a synced place
/// carousel along the bottom — tap a pin to focus its card, tap a card to open it.
struct RestaurantMapView: View {
    @ObservedObject var viewModel: RestaurantListViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selected: Restaurant?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                map
                if !viewModel.restaurants.isEmpty {
                    carousel
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Restaurant.self) { restaurant in
                RestaurantDetailView(restaurant: restaurant)
            }
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
                    RestaurantPin(restaurant: restaurant, isSelected: selected == restaurant)
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.3)) { selected = restaurant }
                        }
                }
                .annotationTitles(.hidden)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .ignoresSafeArea(edges: .top)
    }

    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.restaurants) { restaurant in
                    MapPreviewCard(restaurant: restaurant)
                        .id(restaurant.id)
                        .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: selectionID)
        .frame(height: 92)
        .padding(.bottom, 8)
    }

    /// Two-way binding: focusing a card selects it (and re-tints its pin); tapping
    /// a pin sets `selected`, which scrolls the carousel to that card.
    private var selectionID: Binding<String?> {
        Binding(
            get: { selected?.id },
            set: { newID in
                guard let newID,
                      let match = viewModel.restaurants.first(where: { $0.id == newID })
                else { return }
                selected = match
            }
        )
    }

    private func fitCamera(to restaurants: [Restaurant]) {
        guard !restaurants.isEmpty else { return }
        let coordinates = restaurants.map(\.coordinate)
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        guard
            let minLat = latitudes.min(), let maxLat = latitudes.max(),
            let minLon = longitudes.min(), let maxLon = longitudes.max()
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

// MARK: - Custom pin

private struct RestaurantPin: View {
    let restaurant: Restaurant
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            if isSelected {
                Text(restaurant.name)
                    .font(.caption2.weight(.bold))
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial, in: Capsule())
                    .fixedSize()
            }
            ZStack {
                Circle()
                    .fill(isSelected ? Color.accentColor : Color(.systemBackground))
                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                Image(systemName: restaurant.glyphSymbol)
                    .font(.system(size: isSelected ? 15 : 12, weight: .bold))
                    .foregroundStyle(isSelected ? Color.white : Color.accentColor)
            }
            .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
        }
    }
}

// MARK: - Carousel card

private struct MapPreviewCard: View {
    let restaurant: Restaurant

    var body: some View {
        NavigationLink(value: restaurant) {
            HStack(spacing: 12) {
                CoverArtView(restaurant: restaurant, glyphSize: 22)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if !restaurant.subtitle.isEmpty {
                        Text(restaurant.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if restaurant.canOrderDirect {
                        DirectOrderBadge()
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RestaurantMapView(viewModel: RestaurantListViewModel())
        .environmentObject(FavoritesStore())
}

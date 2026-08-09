import SwiftUI
import MapKit

/// The "Map" tab: nearby restaurants as pins, with a card for the selected one.
struct RestaurantMapView: View {
    @ObservedObject var viewModel: RestaurantListViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedRestaurant: Restaurant?

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, selection: $selectedRestaurant) {
                UserAnnotation()

                ForEach(viewModel.restaurants) { restaurant in
                    Marker(
                        restaurant.name,
                        systemImage: "fork.knife",
                        coordinate: restaurant.coordinate
                    )
                    .tint(.accentColor)
                    .tag(restaurant)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .overlay(alignment: .bottom) {
                if let selectedRestaurant {
                    selectionCard(for: selectedRestaurant)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Restaurant.self) { restaurant in
                RestaurantDetailView(restaurant: restaurant)
            }
            .animation(.spring(duration: 0.3), value: selectedRestaurant)
            .onChange(of: viewModel.restaurants) { _, restaurants in
                fitCamera(to: restaurants)
            }
            .onAppear {
                viewModel.start()
                fitCamera(to: viewModel.restaurants)
            }
        }
    }

    private func selectionCard(for restaurant: Restaurant) -> some View {
        NavigationLink(value: restaurant) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if let distance = restaurant.distanceDescription {
                        Text("\(distance) away · Pickup")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if restaurant.canOrderDirect {
                        DirectOrderBadge()
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(radius: 8, y: 4)
        }
        .buttonStyle(.plain)
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

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.01)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

#Preview {
    RestaurantMapView(viewModel: RestaurantListViewModel())
}

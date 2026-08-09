import Foundation
import MapKit
import CoreLocation

/// Finds nearby restaurants using Apple Maps.
///
/// Uses `MKLocalSearch` so the app works out of the box with no API keys,
/// accounts, or per-request billing. Results carry the restaurant's own
/// website (when Apple Maps has one), which is how RealBite sends users
/// straight to the source to order for pickup — no marketplace markup.
struct RestaurantSearchService {

    /// Food-related points of interest we treat as "restaurants."
    private static let foodCategories: [MKPointOfInterestCategory] = [
        .restaurant, .cafe, .bakery, .brewery, .winery, .foodMarket
    ]

    /// Search around a coordinate. When `query` is empty, returns a broad set of
    /// nearby food POIs; otherwise it filters by the user's search terms.
    func search(
        near center: CLLocationCoordinate2D,
        query: String,
        radiusMeters: CLLocationDistance = 5_000
    ) async throws -> [Restaurant] {
        let request = MKLocalSearch.Request()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        request.naturalLanguageQuery = trimmed.isEmpty ? "restaurants" : trimmed
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(
            including: Self.foodCategories
        )
        request.region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: radiusMeters * 2,
            longitudinalMeters: radiusMeters * 2
        )

        let response = try await MKLocalSearch(request: request).start()
        let origin = CLLocation(latitude: center.latitude, longitude: center.longitude)

        return response.mapItems
            .map { mapItem -> Restaurant in
                var restaurant = Restaurant(mapItem: mapItem)
                let poi = CLLocation(
                    latitude: restaurant.coordinate.latitude,
                    longitude: restaurant.coordinate.longitude
                )
                restaurant.distanceMeters = origin.distance(from: poi)
                return restaurant
            }
            .sorted { ($0.distanceMeters ?? .greatestFiniteMagnitude) < ($1.distanceMeters ?? .greatestFiniteMagnitude) }
    }
}

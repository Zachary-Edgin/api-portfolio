import Foundation
import CoreLocation

/// A restaurant discovered near the user.
///
/// Populated from OpenStreetMap (via the Overpass API) — open data, no API key.
/// The `website` is the restaurant's own URL as listed in OSM; that is what
/// powers "order direct." Fields are best-effort: OSM listings vary in detail.
struct Restaurant: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String?
    let cuisine: String?
    let coordinate: CLLocationCoordinate2D
    let address: String?
    let phoneNumber: String?
    let website: URL?
    let openingHours: String?

    /// Straight-line distance from the user, filled in after a search.
    var distanceMeters: CLLocationDistance?

    init(
        id: String = UUID().uuidString,
        name: String,
        category: String? = nil,
        cuisine: String? = nil,
        coordinate: CLLocationCoordinate2D,
        address: String? = nil,
        phoneNumber: String? = nil,
        website: URL? = nil,
        openingHours: String? = nil,
        distanceMeters: CLLocationDistance? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.cuisine = cuisine
        self.coordinate = coordinate
        self.address = address
        self.phoneNumber = phoneNumber
        self.website = website
        self.openingHours = openingHours
        self.distanceMeters = distanceMeters
    }

    // Hashable/Equatable by id (CLLocationCoordinate2D isn't Hashable).
    static func == (lhs: Restaurant, rhs: Restaurant) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Presentation helpers

extension Restaurant {
    /// True when we can hand the user straight to the restaurant's own site.
    var canOrderDirect: Bool { website != nil }

    /// A short, human distance string, e.g. "0.3 mi".
    var distanceDescription: String? {
        guard let distanceMeters else { return nil }
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: Measurement(value: distanceMeters, unit: UnitLength.meters))
    }

    /// Cuisine formatted for display (OSM stores e.g. "pizza;italian").
    var displayCuisine: String? {
        guard let cuisine, let first = cuisine.split(separator: ";").first else { return nil }
        return first
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    /// One calm metadata line: cuisine (or category) · distance.
    var metaLine: String {
        [displayCuisine ?? category, distanceDescription]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    /// An SF Symbol that suits the restaurant, used on thumbnails and pins.
    var glyphSymbol: String {
        switch category {
        case "Café": return "cup.and.saucer.fill"
        case "Bakery": return "birthday.cake.fill"
        case "Ice cream": return "snowflake"
        default: return "fork.knife"
        }
    }
}

// MARK: - Preview data

extension Restaurant {
    static let previewList: [Restaurant] = [
        Restaurant(
            name: "Blue Door Pizzeria", category: "Restaurant", cuisine: "pizza",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "123 Market St", phoneNumber: "+1 (415) 555-0134",
            website: URL(string: "https://example.com/order"),
            openingHours: "Mo-Su 11:00-22:00", distanceMeters: 480
        ),
        Restaurant(
            name: "Corner Taqueria", category: "Restaurant", cuisine: "mexican",
            coordinate: CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4180),
            address: "88 Mission St", phoneNumber: "+1 (415) 555-0177",
            website: nil, openingHours: nil, distanceMeters: 1_260
        ),
        Restaurant(
            name: "Rise & Grind Café", category: "Café", cuisine: "coffee_shop",
            coordinate: CLLocationCoordinate2D(latitude: 37.7760, longitude: -122.4210),
            address: "500 Howard St", phoneNumber: "+1 (415) 555-0199",
            website: URL(string: "https://example.com/cafe"),
            openingHours: "Mo-Fr 07:00-16:00", distanceMeters: 2_010
        )
    ]
}

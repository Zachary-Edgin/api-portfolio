import Foundation
import MapKit
import CoreLocation

/// A restaurant discovered near the user.
///
/// Backed by an `MKMapItem` from Apple Maps' points-of-interest search, so no
/// third-party API key or account is required. The `website` is the restaurant's
/// own URL when Apple Maps has one on file — that is what powers "order direct."
struct Restaurant: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String?
    let coordinate: CLLocationCoordinate2D
    let address: String?
    let phoneNumber: String?
    let website: URL?

    /// Straight-line distance from the user, filled in after a search.
    var distanceMeters: CLLocationDistance?

    init(
        id: String = UUID().uuidString,
        name: String,
        category: String? = nil,
        coordinate: CLLocationCoordinate2D,
        address: String? = nil,
        phoneNumber: String? = nil,
        website: URL? = nil,
        distanceMeters: CLLocationDistance? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.coordinate = coordinate
        self.address = address
        self.phoneNumber = phoneNumber
        self.website = website
        self.distanceMeters = distanceMeters
    }

    // MARK: Hashable / Equatable (CLLocationCoordinate2D isn't Hashable itself)

    static func == (lhs: Restaurant, rhs: Restaurant) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Restaurant {
    /// Build a `Restaurant` from a MapKit search result.
    init(mapItem: MKMapItem) {
        let placemark = mapItem.placemark
        self.init(
            id: mapItem.identifier?.rawValue ?? UUID().uuidString,
            name: mapItem.name ?? "Unknown restaurant",
            category: Restaurant.readableCategory(for: mapItem.pointOfInterestCategory),
            coordinate: placemark.coordinate,
            address: Restaurant.formatAddress(from: placemark),
            phoneNumber: mapItem.phoneNumber,
            website: mapItem.url
        )
    }

    /// A short, human-facing distance string, e.g. "0.3 mi" or "420 ft".
    var distanceDescription: String? {
        guard let distanceMeters else { return nil }
        let measurement = Measurement(value: distanceMeters, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: measurement)
    }

    /// True when we can hand the user straight to the restaurant's own ordering page.
    var canOrderDirect: Bool { website != nil }

    /// First letter of the name, for cover-art fallbacks.
    var monogram: String {
        String(name.trimmingCharacters(in: .whitespaces).first.map(String.init) ?? "•").uppercased()
    }

    /// Stable seed (name-derived) so a restaurant's generated cover art stays
    /// consistent between the list, map, and detail screens.
    var coverSeed: Int {
        name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
    }

    /// An SF Symbol that suits the restaurant's category, used on cover art and pins.
    var glyphSymbol: String {
        switch category {
        case "Café": return "cup.and.saucer.fill"
        case "Brewery", "Winery": return "wineglass.fill"
        case "Bakery": return "birthday.cake.fill"
        default: return "fork.knife"
        }
    }

    /// Compact "Category · Distance" line used across cards.
    var subtitle: String {
        [category, distanceDescription].compactMap { $0 }.joined(separator: " · ")
    }

    private static func formatAddress(from placemark: MKPlacemark) -> String? {
        let parts = [
            placemark.thoroughfare.flatMap { street in
                placemark.subThoroughfare.map { "\($0) \(street)" } ?? street
            },
            placemark.locality,
            placemark.administrativeArea
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private static func readableCategory(for category: MKPointOfInterestCategory?) -> String? {
        guard let category else { return nil }
        switch category {
        case .restaurant: return "Restaurant"
        case .cafe: return "Café"
        case .bakery: return "Bakery"
        case .brewery: return "Brewery"
        case .winery: return "Winery"
        case .foodMarket: return "Food Market"
        default: return "Food"
        }
    }
}

extension Restaurant {
    /// Sample data for SwiftUI previews.
    static let previewList: [Restaurant] = [
        Restaurant(
            name: "Blue Door Pizzeria",
            category: "Restaurant",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            address: "123 Market St, San Francisco, CA",
            phoneNumber: "+1 (415) 555-0134",
            website: URL(string: "https://example.com/order"),
            distanceMeters: 480
        ),
        Restaurant(
            name: "Corner Taqueria",
            category: "Restaurant",
            coordinate: CLLocationCoordinate2D(latitude: 37.7752, longitude: -122.4180),
            address: "88 Mission St, San Francisco, CA",
            phoneNumber: "+1 (415) 555-0177",
            website: nil,
            distanceMeters: 1_260
        ),
        Restaurant(
            name: "Rise & Grind Café",
            category: "Café",
            coordinate: CLLocationCoordinate2D(latitude: 37.7760, longitude: -122.4210),
            address: "500 Howard St, San Francisco, CA",
            phoneNumber: "+1 (415) 555-0199",
            website: URL(string: "https://example.com/cafe"),
            distanceMeters: 2_010
        )
    ]
}

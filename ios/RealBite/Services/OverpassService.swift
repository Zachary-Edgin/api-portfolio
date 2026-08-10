import Foundation
import CoreLocation

/// Fetches nearby restaurants from OpenStreetMap via the Overpass API.
///
/// Open data, no API key, no account, no billing. Results carry the restaurant's
/// own website (OSM `website` tag) — the link RealBite uses to send users straight
/// to the source to order for pickup, with no marketplace markup.
struct OverpassService {

    enum ServiceError: LocalizedError {
        case badResponse
        case decoding

        var errorDescription: String? {
            switch self {
            case .badResponse: return "The restaurant service didn't respond. Please try again."
            case .decoding: return "We couldn't read the restaurant data. Please try again."
            }
        }
    }

    /// Public Overpass mirrors, tried in order for resilience.
    private let endpoints = [
        "https://overpass-api.de/api/interpreter",
        "https://overpass.kumi.systems/api/interpreter"
    ]

    /// Search around a coordinate. `filter` is an Overpass tag selector such as
    /// `["amenity"~"cafe"]` (see ``FoodCategory``); build a name filter for text search.
    func search(
        near center: CLLocationCoordinate2D,
        filter: String,
        radiusMeters: Double = 4_000,
        limit: Int = 60
    ) async throws -> [Restaurant] {
        let query = """
        [out:json][timeout:25];
        (
          node\(filter)(around:\(Int(radiusMeters)),\(center.latitude),\(center.longitude));
        );
        out body \(limit);
        """

        var lastError: Error = ServiceError.badResponse
        for endpoint in endpoints {
            do {
                return try await run(query: query, endpoint: endpoint, center: center)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    /// Build a name-search tag filter, e.g. `["amenity"~"..."]["name"~"pizza",i]`.
    static func nameFilter(_ text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\\", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(FoodCategory.base)[\"name\"~\"\(cleaned)\",i]"
    }

    // MARK: - Private

    private func run(
        query: String,
        endpoint: String,
        center: CLLocationCoordinate2D
    ) async throws -> [Restaurant] {
        guard let url = URL(string: endpoint) else { throw ServiceError.badResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        request.httpBody = Data("data=\(encoded)".utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ServiceError.badResponse
        }
        guard let decoded = try? JSONDecoder().decode(OverpassResponse.self, from: data) else {
            throw ServiceError.decoding
        }

        let origin = CLLocation(latitude: center.latitude, longitude: center.longitude)
        return decoded.elements
            .compactMap { Restaurant(overpass: $0, origin: origin) }
            .sorted { ($0.distanceMeters ?? .greatestFiniteMagnitude) < ($1.distanceMeters ?? .greatestFiniteMagnitude) }
    }
}

// MARK: - Overpass response

struct OverpassResponse: Decodable {
    let elements: [OverpassElement]
}

struct OverpassElement: Decodable {
    let type: String
    let id: Int
    let lat: Double?
    let lon: Double?
    let center: Center?
    let tags: [String: String]?

    struct Center: Decodable { let lat: Double; let lon: Double }

    var coordinate: CLLocationCoordinate2D? {
        if let lat, let lon { return CLLocationCoordinate2D(latitude: lat, longitude: lon) }
        if let center { return CLLocationCoordinate2D(latitude: center.lat, longitude: center.lon) }
        return nil
    }
}

// MARK: - Mapping OSM → Restaurant

extension Restaurant {
    init?(overpass element: OverpassElement, origin: CLLocation) {
        guard
            let tags = element.tags,
            let name = tags["name"],
            let coordinate = element.coordinate
        else { return nil }

        let poi = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        self.init(
            id: "\(element.type)/\(element.id)",
            name: name,
            category: Restaurant.readableCategory(tags["amenity"]),
            cuisine: tags["cuisine"],
            coordinate: coordinate,
            address: Restaurant.composeAddress(from: tags),
            phoneNumber: tags["phone"] ?? tags["contact:phone"],
            website: Restaurant.normalizedURL(tags["website"] ?? tags["contact:website"]),
            openingHours: tags["opening_hours"],
            distanceMeters: origin.distance(from: poi)
        )
    }

    fileprivate static func readableCategory(_ amenity: String?) -> String? {
        switch amenity {
        case "restaurant": return "Restaurant"
        case "cafe": return "Café"
        case "fast_food": return "Fast food"
        case "bakery": return "Bakery"
        case "ice_cream": return "Ice cream"
        default: return nil
        }
    }

    fileprivate static func composeAddress(from tags: [String: String]) -> String? {
        let street: String? = {
            guard let road = tags["addr:street"] else { return nil }
            if let number = tags["addr:housenumber"] { return "\(number) \(road)" }
            return road
        }()
        let parts = [street, tags["addr:city"]].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    fileprivate static func normalizedURL(_ raw: String?) -> URL? {
        guard var value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        if !value.lowercased().hasPrefix("http") { value = "https://\(value)" }
        return URL(string: value)
    }
}

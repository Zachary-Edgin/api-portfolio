import Foundation

/// Persists the user's favorite restaurants across launches using `UserDefaults`.
/// Small and synchronous — favorites are just a set of restaurant identifiers.
@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var ids: Set<String>

    private let key = "realbite.favorites"

    init() {
        ids = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    func isFavorite(_ restaurant: Restaurant) -> Bool {
        ids.contains(restaurant.id)
    }

    func toggle(_ restaurant: Restaurant) {
        if ids.contains(restaurant.id) {
            ids.remove(restaurant.id)
        } else {
            ids.insert(restaurant.id)
        }
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}

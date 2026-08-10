import Foundation

/// A quick-filter category shown as a chip row. Each carries the OpenStreetMap
/// tag filter (the part after `node` in an Overpass query) used to fetch it.
struct FoodCategory: Identifiable, Hashable {
    let id = UUID()
    let label: String
    /// Overpass tag selector, e.g. `["amenity"~"cafe"]`.
    let overpass: String

    static let base = #"["amenity"~"restaurant|cafe|fast_food|bakery|ice_cream"]"#

    static let presets: [FoodCategory] = [
        FoodCategory(label: "All", overpass: base),
        FoodCategory(label: "Pizza", overpass: #"["amenity"~"restaurant|fast_food"]["cuisine"~"pizza",i]"#),
        FoodCategory(label: "Burgers", overpass: #"["amenity"~"restaurant|fast_food"]["cuisine"~"burger",i]"#),
        FoodCategory(label: "Sushi", overpass: #"["amenity"~"restaurant|fast_food"]["cuisine"~"sushi|japanese",i]"#),
        FoodCategory(label: "Mexican", overpass: #"["amenity"~"restaurant|fast_food"]["cuisine"~"mexican|taco",i]"#),
        FoodCategory(label: "Coffee", overpass: #"["amenity"~"cafe"]"#),
        FoodCategory(label: "Bakery", overpass: #"["amenity"~"bakery"]"#),
        FoodCategory(label: "Vegan", overpass: #"["amenity"~"restaurant|cafe|fast_food"]["cuisine"~"vegan|vegetarian",i]"#),
        FoodCategory(label: "Chinese", overpass: #"["amenity"~"restaurant|fast_food"]["cuisine"~"chinese|asian",i]"#),
        FoodCategory(label: "Thai", overpass: #"["amenity"~"restaurant|fast_food"]["cuisine"~"thai",i]"#)
    ]
}

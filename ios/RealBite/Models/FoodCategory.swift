import Foundation

/// A quick-filter category shown as a chip row above the results. Selecting one
/// re-runs the nearby search with its query term.
struct FoodCategory: Identifiable, Hashable {
    let id = UUID()
    let label: String
    /// The search term to run, or `nil` for "All" (broad nearby search).
    let query: String?

    static let presets: [FoodCategory] = [
        FoodCategory(label: "All", query: nil),
        FoodCategory(label: "Pizza", query: "pizza"),
        FoodCategory(label: "Burgers", query: "burgers"),
        FoodCategory(label: "Sushi", query: "sushi"),
        FoodCategory(label: "Tacos", query: "tacos"),
        FoodCategory(label: "Coffee", query: "coffee"),
        FoodCategory(label: "Bakery", query: "bakery"),
        FoodCategory(label: "Vegan", query: "vegan"),
        FoodCategory(label: "Chinese", query: "chinese"),
        FoodCategory(label: "Thai", query: "thai")
    ]
}

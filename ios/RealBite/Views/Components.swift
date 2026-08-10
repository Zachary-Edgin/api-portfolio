import SwiftUI

// MARK: - Color from hex

extension Color {
    /// Create a color from a 24-bit RGB hex value, e.g. `Color(hex: 0xBF5A38)`.
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

// MARK: - Minimal category chip

/// An understated pill in the category filter row. Selected state is a soft
/// accent tint — no hard fills, keeping the row calm.
struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.accentColor.opacity(0.12) : Color.clear,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Minimal thumbnail

/// A calm, monochrome tile used in place of photography (OpenStreetMap has none):
/// a soft accent-tinted square with the category glyph.
struct Thumbnail: View {
    let restaurant: Restaurant
    var size: CGFloat = 54

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(Color.accentColor.opacity(0.10))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: restaurant.glyphSymbol)
                    .font(.system(size: size * 0.4, weight: .regular))
                    .foregroundStyle(Color.accentColor)
            )
    }
}

// MARK: - Favorite button

/// Plain heart toggle backed by ``FavoritesStore`` — for the detail toolbar.
struct FavoriteButton: View {
    let restaurant: Restaurant
    @EnvironmentObject private var favorites: FavoritesStore

    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) { favorites.toggle(restaurant) }
        } label: {
            let isFav = favorites.isFavorite(restaurant)
            Image(systemName: isFav ? "heart.fill" : "heart")
                .foregroundStyle(isFav ? .red : Color.accentColor)
                .symbolEffect(.bounce, value: isFav)
        }
        .accessibilityLabel(favorites.isFavorite(restaurant) ? "Remove favorite" : "Add favorite")
    }
}

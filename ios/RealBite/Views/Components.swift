import SwiftUI

// MARK: - Color from hex

extension Color {
    /// Create a color from a 24-bit RGB hex value, e.g. `Color(hex: 0xE6734C)`.
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

// MARK: - "Order direct" badge

/// Signals we can send the user straight to the restaurant's own site.
struct DirectOrderBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "arrow.up.right")
                .font(.system(size: 9, weight: .heavy))
            Text("Order direct")
                .font(.caption2.weight(.bold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.green.opacity(0.16), in: Capsule())
        .foregroundStyle(.green)
    }
}

// MARK: - Glass meta pill (used over cover art)

/// A frosted capsule for metadata overlaid on colorful cover art.
struct MetaPill: View {
    var systemImage: String? = nil
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Favorite button

/// Heart toggle backed by ``FavoritesStore``. The `glass` variant sits on
/// cover art (frosted circle, white/red heart); the plain variant is for toolbars.
struct FavoriteButton: View {
    let restaurant: Restaurant
    var glass: Bool = true

    @EnvironmentObject private var favorites: FavoritesStore

    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) {
                favorites.toggle(restaurant)
            }
        } label: {
            let isFav = favorites.isFavorite(restaurant)
            Image(systemName: isFav ? "heart.fill" : "heart")
                .font(.system(size: glass ? 15 : 17, weight: .bold))
                .foregroundStyle(isFav ? .red : (glass ? .white : .primary))
                .symbolEffect(.bounce, value: isFav)
                .modifier(GlassCircle(enabled: glass))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(favorites.isFavorite(restaurant) ? "Remove favorite" : "Add favorite")
    }
}

private struct GlassCircle: ViewModifier {
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled {
            content
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
                .environment(\.colorScheme, .dark)
        } else {
            content
        }
    }
}

// MARK: - Category chip

/// A selectable pill in the category filter row.
struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.accentColor : Color(.secondarySystemBackground),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

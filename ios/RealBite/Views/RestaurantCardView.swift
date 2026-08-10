import SwiftUI

/// Image-forward restaurant card for the Nearby list: generated cover art with a
/// distance pill and favorite heart overlaid, then name and metadata below.
struct RestaurantCardView: View {
    let restaurant: Restaurant

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: restaurant) {
                VStack(alignment: .leading, spacing: 0) {
                    cover
                    details
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            }
            .buttonStyle(.plain)

            // Sits above the link so its taps toggle the favorite instead of navigating.
            FavoriteButton(restaurant: restaurant)
                .padding(12)
        }
    }

    private var cover: some View {
        CoverArtView(restaurant: restaurant, glyphSize: 48)
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 8) {
                    if let distance = restaurant.distanceDescription {
                        MetaPill(systemImage: "location.fill", text: distance)
                    }
                    MetaPill(systemImage: "bag.fill", text: "Pickup")
                }
                .padding(12)
            }
            .clipped()
    }

    private var details: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if !restaurant.subtitle.isEmpty {
                        Text(restaurant.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if restaurant.canOrderDirect {
                        DirectOrderBadge()
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(Restaurant.previewList) { restaurant in
                RestaurantCardView(restaurant: restaurant)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .environmentObject(FavoritesStore())
}

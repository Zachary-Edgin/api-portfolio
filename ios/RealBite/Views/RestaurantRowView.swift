import SwiftUI

/// A calm, typographic list row: thumbnail, name, one line of metadata, and a
/// small accent arrow when you can order directly from the restaurant's site.
struct RestaurantRowView: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 14) {
            Thumbnail(restaurant: restaurant, size: 54)

            VStack(alignment: .leading, spacing: 3) {
                Text(restaurant.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if !restaurant.metaLine.isEmpty {
                    HStack(spacing: 6) {
                        Text(restaurant.metaLine)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if restaurant.canOrderDirect {
                            Text("· Order direct")
                                .foregroundStyle(Color.accentColor)
                                .lineLimit(1)
                                .layoutPriority(1)
                        }
                    }
                    .font(.subheadline)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    List(Restaurant.previewList) { restaurant in
        RestaurantRowView(restaurant: restaurant)
    }
    .listStyle(.plain)
}

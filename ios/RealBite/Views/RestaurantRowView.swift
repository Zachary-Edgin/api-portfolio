import SwiftUI

/// A single restaurant in the nearby list.
struct RestaurantRowView: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                Image(systemName: "fork.knife")
                    .foregroundStyle(Color.accentColor)
                    .font(.system(size: 18, weight: .semibold))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(restaurant.name)
                    .font(.headline)
                    .lineLimit(1)

                if let address = restaurant.address {
                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    if let distance = restaurant.distanceDescription {
                        Label(distance, systemImage: "location.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if restaurant.canOrderDirect {
                        DirectOrderBadge()
                    }
                }
                .padding(.top, 1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

/// Small pill that signals we can send the user straight to the restaurant's site.
struct DirectOrderBadge: View {
    var body: some View {
        Text("Order direct")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.16), in: Capsule())
            .foregroundStyle(Color.green)
    }
}

#Preview {
    List(Restaurant.previewList) { restaurant in
        RestaurantRowView(restaurant: restaurant)
    }
}

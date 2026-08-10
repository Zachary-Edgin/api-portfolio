import SwiftUI

/// The "Nearby" tab: a calm category row over a clean, typographic list of
/// restaurants you can order from directly for pickup.
struct RestaurantListView: View {
    @ObservedObject var viewModel: RestaurantListViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryRow
                content
            }
            .navigationTitle("Nearby")
            .navigationDestination(for: Restaurant.self) { restaurant in
                RestaurantDetailView(restaurant: restaurant)
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search restaurants"
            )
            .onSubmit(of: .search) { viewModel.submitTextSearch() }
            .task { viewModel.start() }
        }
    }

    private var categoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(FoodCategory.presets) { category in
                    CategoryChip(
                        label: category.label,
                        isSelected: category.id == viewModel.selectedCategory.id
                    ) {
                        viewModel.select(category)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle, .locating:
            StatusView(title: "Finding your location",
                       message: "Looking for restaurants near you.",
                       showsProgress: true)

        case .loading:
            SkeletonList()

        case let .loaded(restaurants):
            list(restaurants)

        case .empty:
            StatusView(systemImage: "magnifyingglass",
                       title: "Nothing nearby",
                       message: "Try another category or search, or widen your area.",
                       actionTitle: "Reset",
                       action: { viewModel.select(FoodCategory.presets[0]) })

        case let .failed(message):
            StatusView(systemImage: "wifi.exclamationmark",
                       title: "Couldn’t load",
                       message: message,
                       actionTitle: "Try again",
                       action: viewModel.retry)
        }
    }

    private func list(_ restaurants: [Restaurant]) -> some View {
        List {
            ForEach(restaurants) { restaurant in
                NavigationLink(value: restaurant) {
                    RestaurantRowView(restaurant: restaurant)
                }
                .listRowInsets(EdgeInsets(top: 2, leading: 20, bottom: 2, trailing: 20))
                .listRowSeparatorTint(Color.primary.opacity(0.06))
            }
        }
        .listStyle(.plain)
        .refreshable { viewModel.performSearch() }
    }
}

// MARK: - Loading skeleton

private struct SkeletonList: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { _ in
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                        .frame(width: 54, height: 54)
                    VStack(alignment: .leading, spacing: 7) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.06)).frame(width: 150, height: 12)
                        RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.05)).frame(width: 90, height: 10)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            Spacer()
        }
        .padding(.top, 4)
        .allowsHitTesting(false)
    }
}

// MARK: - Full-screen status

private struct StatusView: View {
    var systemImage: String? = nil
    let title: String
    let message: String
    var showsProgress: Bool = false
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            if showsProgress {
                ProgressView()
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 5) {
                Text(title).font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .tint(.accentColor)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RestaurantListView(viewModel: RestaurantListViewModel())
        .environmentObject(FavoritesStore())
}

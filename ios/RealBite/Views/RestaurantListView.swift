import SwiftUI

/// The "Nearby" tab: a category chip row over an image-forward list of
/// restaurants you can order from directly for pickup.
struct RestaurantListView: View {
    @ObservedObject var viewModel: RestaurantListViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryChips
                Divider().opacity(0.5)
                content
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Nearby")
            .navigationDestination(for: Restaurant.self) { restaurant in
                RestaurantDetailView(restaurant: restaurant)
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search food or a restaurant"
            )
            .onSubmit(of: .search) {
                viewModel.selectedCategory = FoodCategory.presets[0]
                viewModel.performSearch()
            }
            .task { viewModel.start() }
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FoodCategory.presets) { category in
                    CategoryChip(
                        label: category.label,
                        isSelected: category.id == viewModel.selectedCategory.id
                    ) {
                        viewModel.select(category)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle, .locating:
            StatusView(systemImage: "location.magnifyingglass",
                       title: "Finding your location",
                       message: "Hang tight while we look for restaurants near you.",
                       showsProgress: true)

        case .loading:
            LoadingList()

        case let .loaded(restaurants):
            restaurantList(restaurants)

        case .empty:
            StatusView(systemImage: "magnifyingglass",
                       title: "No restaurants found",
                       message: "Try a different category or search, or widen your area.",
                       actionTitle: "Reset",
                       action: { viewModel.select(FoodCategory.presets[0]) })

        case let .failed(message):
            StatusView(systemImage: "exclamationmark.triangle",
                       title: "Something went wrong",
                       message: message,
                       actionTitle: "Try again",
                       action: viewModel.retry)
        }
    }

    private func restaurantList(_ restaurants: [Restaurant]) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                Text("Order directly from the restaurant — real prices, pickup only.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)

                ForEach(restaurants) { restaurant in
                    RestaurantCardView(restaurant: restaurant)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .refreshable { viewModel.performSearch() }
    }
}

// MARK: - Loading placeholder (shimmering cards)

private struct LoadingList: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(height: 196)
                        .redacted(reason: .placeholder)
                        .shimmer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Full-screen status

private struct StatusView: View {
    let systemImage: String
    let title: String
    let message: String
    var showsProgress: Bool = false
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            if showsProgress {
                ProgressView().controlSize(.large)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 44))
                    .foregroundStyle(Color.accentColor)
            }
            VStack(spacing: 6) {
                Text(title).font(.title3.weight(.semibold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Shimmer

private struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.35), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(16))
                .offset(x: phase * 320)
                .blendMode(.plusLighter)
            )
            .mask(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.4
                }
            }
    }
}

private extension View {
    func shimmer() -> some View { modifier(Shimmer()) }
}

#Preview {
    RestaurantListView(viewModel: RestaurantListViewModel())
        .environmentObject(FavoritesStore())
}

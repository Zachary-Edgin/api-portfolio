import SwiftUI

/// The "Nearby" tab: a searchable list of restaurants around the user.
struct RestaurantListView: View {
    @ObservedObject var viewModel: RestaurantListViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Nearby")
                .navigationDestination(for: Restaurant.self) { restaurant in
                    RestaurantDetailView(restaurant: restaurant)
                }
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search food or a restaurant"
        )
        .onSubmit(of: .search) {
            viewModel.performSearch()
        }
        .task {
            viewModel.start()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle, .locating:
            StatusView(
                systemImage: "location.magnifyingglass",
                title: "Finding your location",
                message: "Hang tight while we look for restaurants near you.",
                showsProgress: true
            )

        case .loading:
            StatusView(
                systemImage: "fork.knife",
                title: "Searching nearby",
                message: "Looking for restaurants you can order from directly.",
                showsProgress: true
            )

        case let .loaded(restaurants):
            restaurantList(restaurants)

        case .empty:
            StatusView(
                systemImage: "magnifyingglass",
                title: "No restaurants found",
                message: "Try a different search or widen your area.",
                actionTitle: "Search again",
                action: viewModel.retry
            )

        case let .failed(message):
            StatusView(
                systemImage: "exclamationmark.triangle",
                title: "Something went wrong",
                message: message,
                actionTitle: "Try again",
                action: viewModel.retry
            )
        }
    }

    private func restaurantList(_ restaurants: [Restaurant]) -> some View {
        List {
            Section {
                ForEach(restaurants) { restaurant in
                    NavigationLink(value: restaurant) {
                        RestaurantRowView(restaurant: restaurant)
                    }
                }
            } header: {
                Text("Order directly from the restaurant — real prices, pickup only.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textCase(nil)
                    .padding(.bottom, 2)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.performSearch()
        }
    }
}

/// Reusable full-screen state (loading / empty / error).
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
                ProgressView()
                    .controlSize(.large)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 44))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
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

#Preview {
    RestaurantListView(viewModel: RestaurantListViewModel())
}

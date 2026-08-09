import SwiftUI

/// Top-level container. Shares one view model between the list and map tabs so
/// both show the same set of nearby restaurants.
struct RootView: View {
    @StateObject private var viewModel = RestaurantListViewModel()

    var body: some View {
        TabView {
            RestaurantListView(viewModel: viewModel)
                .tabItem {
                    Label("Nearby", systemImage: "fork.knife")
                }

            RestaurantMapView(viewModel: viewModel)
                .tabItem {
                    Label("Map", systemImage: "map")
                }
        }
        .tint(.accentColor)
    }
}

#Preview {
    RootView()
}

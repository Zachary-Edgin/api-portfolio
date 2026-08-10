import SwiftUI

/// Top-level container. Shows the location onboarding gate until access is
/// granted, then the main tabs. One view model and one favorites store are
/// shared across the whole app.
struct RootView: View {
    @StateObject private var viewModel = RestaurantListViewModel()
    @StateObject private var favorites = FavoritesStore()

    var body: some View {
        Group {
            if viewModel.isLocationReady {
                MainTabView(viewModel: viewModel)
                    .transition(.opacity)
            } else {
                OnboardingView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .environmentObject(favorites)
        .animation(.easeInOut(duration: 0.35), value: viewModel.isLocationReady)
    }
}

/// The two-tab experience once the user is onboarded.
private struct MainTabView: View {
    @ObservedObject var viewModel: RestaurantListViewModel

    var body: some View {
        TabView {
            RestaurantListView(viewModel: viewModel)
                .tabItem { Label("Nearby", systemImage: "fork.knife") }

            RestaurantMapView(viewModel: viewModel)
                .tabItem { Label("Map", systemImage: "map") }
        }
        .tint(.accentColor)
    }
}

#Preview {
    RootView()
}

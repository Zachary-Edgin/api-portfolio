import Foundation
import CoreLocation
import Combine

/// Drives the nearby-restaurants screens: owns location, runs OpenStreetMap
/// searches (by category or free text), and exposes a simple `phase` to render.
@MainActor
final class RestaurantListViewModel: ObservableObject {

    enum Phase: Equatable {
        case idle
        case locating
        case loading
        case loaded([Restaurant])
        case empty
        case failed(String)
    }

    @Published private(set) var phase: Phase = .idle
    @Published var searchText: String = ""
    @Published var selectedCategory: FoodCategory = FoodCategory.presets[0]
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    let locationManager = LocationManager()
    private let service: OverpassService
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    private var hasRequestedInitialSearch = false

    init(service: OverpassService = OverpassService()) {
        self.service = service
        self.authorizationStatus = locationManager.authorizationStatus
        observeLocation()
    }

    var restaurants: [Restaurant] {
        if case let .loaded(list) = phase { return list }
        return []
    }

    var isLocationReady: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    // MARK: - Intent

    /// Called when the main screen first appears.
    func start() {
        if isLocationReady {
            locationManager.requestLocation()
        } else if authorizationStatus == .notDetermined {
            phase = .locating
            locationManager.requestLocation()
        } else {
            phase = .failed(Self.permissionMessage)
        }
    }

    /// Pick a quick-filter category and re-run the search.
    func select(_ category: FoodCategory) {
        selectedCategory = category
        searchText = ""
        performSearch()
    }

    /// Run a free-text search; resets the category chips to "All".
    func submitTextSearch() {
        selectedCategory = FoodCategory.presets[0]
        performSearch()
    }

    /// Re-run the search against the latest known location.
    func performSearch() {
        guard let location = locationManager.location else {
            locationManager.requestLocation()
            phase = .locating
            return
        }
        runSearch(near: location.coordinate)
    }

    func retry() {
        hasRequestedInitialSearch = false
        start()
    }

    // MARK: - Private

    private func observeLocation() {
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self, !self.hasRequestedInitialSearch else { return }
                self.hasRequestedInitialSearch = true
                self.runSearch(near: location.coordinate)
            }
            .store(in: &cancellables)

        locationManager.$authorizationStatus
            .sink { [weak self] status in
                guard let self else { return }
                self.authorizationStatus = status
                if status == .denied || status == .restricted {
                    self.phase = .failed(Self.permissionMessage)
                }
            }
            .store(in: &cancellables)
    }

    private var currentFilter: String {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? selectedCategory.overpass : OverpassService.nameFilter(text)
    }

    private func runSearch(near center: CLLocationCoordinate2D) {
        searchTask?.cancel()
        phase = .loading
        let filter = currentFilter
        searchTask = Task {
            do {
                let results = try await service.search(near: center, filter: filter)
                if Task.isCancelled { return }
                self.phase = results.isEmpty ? .empty : .loaded(results)
            } catch is CancellationError {
                // Superseded by a newer search.
            } catch {
                if Task.isCancelled { return }
                self.phase = .failed(error.localizedDescription)
            }
        }
    }

    static let permissionMessage =
        "RealBite needs your location to find restaurants nearby. Enable location access in Settings to get started."
}

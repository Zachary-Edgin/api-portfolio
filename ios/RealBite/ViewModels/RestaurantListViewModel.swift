import Foundation
import CoreLocation
import Combine

/// Drives the nearby-restaurants screens: owns location, runs searches, and
/// exposes a simple `phase` the views render from.
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

    let locationManager = LocationManager()
    private let searchService: RestaurantSearchService
    private var cancellables = Set<AnyCancellable>()
    private var hasRequestedInitialSearch = false

    init(searchService: RestaurantSearchService = RestaurantSearchService()) {
        self.searchService = searchService
        observeLocation()
    }

    var restaurants: [Restaurant] {
        if case let .loaded(list) = phase { return list }
        return []
    }

    /// Called when the main screen first appears.
    func start() {
        if locationManager.isAuthorized {
            locationManager.requestLocation()
        } else if locationManager.authorizationStatus == .notDetermined {
            phase = .locating
            locationManager.requestLocation()
        } else {
            phase = .failed(Self.permissionMessage)
        }
    }

    /// Re-run the search with the current text against the latest known location.
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
                if status == .denied || status == .restricted {
                    self.phase = .failed(Self.permissionMessage)
                }
            }
            .store(in: &cancellables)
    }

    private func runSearch(near center: CLLocationCoordinate2D) {
        phase = .loading
        let query = searchText
        Task {
            do {
                let results = try await searchService.search(near: center, query: query)
                self.phase = results.isEmpty ? .empty : .loaded(results)
            } catch is CancellationError {
                // Ignore — a newer search superseded this one.
            } catch {
                self.phase = .failed("Couldn't load restaurants. \(error.localizedDescription)")
            }
        }
    }

    static let permissionMessage =
        "RealBite needs your location to find restaurants nearby. Enable location access in Settings to get started."
}

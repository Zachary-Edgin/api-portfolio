# RealBite — Order Direct. Real Prices. Pickup Only.

A native iOS app that helps you find nearby restaurants and order **directly from
the restaurant's own website** for pickup — instead of going through delivery
marketplaces (Uber Eats, DoorDash, and the like) that inflate menu prices with
commissions and tack on service fees to cover them.

RealBite doesn't process orders or take a cut. It finds restaurants near you and
hands you straight to the source: the restaurant's real menu, the real price.

> Pickup only — RealBite is intentionally not a delivery app. That's the whole point.

---

## Why it exists

Delivery apps commonly mark up menu prices **and** add service, delivery, and
"small order" fees, so the same burrito can cost far more through a marketplace
than at the counter. For **pickup**, none of that is necessary. RealBite closes
the gap by pointing you at the restaurant's own ordering page, where you pay what
the restaurant actually charges.

---

## Features

- **Nearby search** — finds restaurants, cafés, bakeries, and more around your
  current location.
- **Search by name or cuisine** — type "tacos", "pizza", or a restaurant name.
- **List + Map** — browse a distance-sorted list or see everything on a map.
- **Order direct** — opens the restaurant's own website in an in-app browser so
  you order from the source (no marketplace markup). An "Order direct" badge
  flags restaurants that publish an ordering page.
- **Directions & Call** — one tap to Apple Maps directions or to phone the
  restaurant.
- **No accounts, no API keys** — restaurant discovery uses Apple Maps
  (`MKLocalSearch`), so the app runs out of the box with nothing to configure.

---

## Tech stack

- **SwiftUI** (iOS 17+), MVVM architecture
- **MapKit** — `MKLocalSearch` for restaurant discovery, `Map` for the map tab
- **CoreLocation** — one-shot "when in use" location for nearby search
- **SafariServices** — `SFSafariViewController` for in-app direct ordering

## Project layout

```
ios/
├─ RealBite.xcodeproj          # Xcode project (file-system-synchronized groups)
└─ RealBite/
   ├─ RealBiteApp.swift        # App entry point
   ├─ Models/
   │  └─ Restaurant.swift      # Restaurant model (+ MKMapItem mapping)
   ├─ Services/
   │  ├─ LocationManager.swift        # CoreLocation wrapper
   │  └─ RestaurantSearchService.swift # MKLocalSearch nearby search
   ├─ ViewModels/
   │  └─ RestaurantListViewModel.swift # State + search orchestration
   ├─ Views/
   │  ├─ RootView.swift               # Tab container (Nearby / Map)
   │  ├─ RestaurantListView.swift     # Searchable nearby list + states
   │  ├─ RestaurantRowView.swift      # List row
   │  ├─ RestaurantDetailView.swift   # Detail + "Order for Pickup"
   │  ├─ RestaurantMapView.swift      # Map with pins + selection card
   │  └─ SafariView.swift             # In-app browser for direct ordering
   └─ Assets.xcassets/         # App icon + accent color
```

## Running it

Requires **Xcode 16+** on macOS (the project uses file-system-synchronized
groups) and iOS 17+ to run.

1. Open `ios/RealBite.xcodeproj` in Xcode.
2. Select the **RealBite** scheme and an iOS 17+ simulator or device.
3. Run (⌘R).

On the **Simulator**, set a location so nearby search returns results:
**Features ▸ Location ▸ Apple** (or **Custom Location…**). On a device, grant
location permission when prompted.

From the command line:

```bash
cd ios
xcodebuild -project RealBite.xcodeproj -scheme RealBite \
  -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## How ordering works

RealBite never places an order itself and adds no fees. When you tap **Order for
Pickup**, it opens the restaurant's own website (as provided by Apple Maps) in an
in-app Safari view. If a restaurant hasn't published an ordering page, RealBite
offers to search the web for their menu or to call them directly.

## Notes & limitations

- Restaurant data (including websites) comes from Apple Maps and is only as
  complete as Apple's listings. Not every restaurant publishes an online
  ordering URL.
- Hours, live availability, and menus are not shown — RealBite is a discovery and
  hand-off tool, not an ordering backend.
- Pickup only, by design.

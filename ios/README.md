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

- **Onboarding gate** — a branded location-permission screen that doubles as the
  "enable in Settings" prompt if access was denied.
- **Nearby search** — finds restaurants, cafés, bakeries, and more around your
  current location.
- **Category chips** — one-tap filters (Pizza, Sushi, Coffee, Tacos, Vegan…) that
  re-run the nearby search.
- **Search by name or cuisine** — type "tacos", "pizza", or a restaurant name.
- **Image-forward cards** — each restaurant gets tasteful generated cover art
  (MapKit provides no photos), with glass distance/pickup pills and a favorite
  heart. Favorites persist across launches.
- **List + Map** — browse distance-sorted cards or a map with custom pins and a
  synced place carousel (tap a pin to focus its card).
- **Order direct** — a hero detail screen with a sticky **Order for Pickup** bar
  that opens the restaurant's own website in an in-app browser (no marketplace
  markup). An "Order direct" badge flags restaurants that publish an ordering page.
- **Directions & Call** — one tap to Apple Maps directions or to phone the
  restaurant.
- **No accounts, no API keys** — restaurant discovery uses Apple Maps
  (`MKLocalSearch`), so the app runs out of the box with nothing to configure.
- **Polished states** — shimmering skeleton cards while loading, plus clear
  empty/error states.

### Design

The UI follows contemporary food/discovery app patterns (the kind catalogued on
[Mobbin](https://mobbin.com/explore/mobile)): an onboarding gate, filter chips,
image-forward cards with glass overlays and favorite hearts, a hero cover with a
sticky bottom order bar, and a map with custom pins plus a place carousel. Cover
art is generated deterministically per restaurant, so it stays consistent across
list, map, and detail without inventing photos or ratings the data doesn't have.

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
   │  ├─ Restaurant.swift      # Restaurant model (+ MKMapItem mapping, cover art seed)
   │  └─ FoodCategory.swift    # Quick-filter chip presets
   ├─ Services/
   │  ├─ LocationManager.swift         # CoreLocation wrapper
   │  ├─ RestaurantSearchService.swift # MKLocalSearch nearby search
   │  └─ FavoritesStore.swift          # Persisted favorites (UserDefaults)
   ├─ ViewModels/
   │  └─ RestaurantListViewModel.swift # State + search + category orchestration
   ├─ Views/
   │  ├─ RootView.swift               # Onboarding gate → tab container
   │  ├─ OnboardingView.swift         # Branded location-permission screen
   │  ├─ RestaurantListView.swift     # Chips + card list + states
   │  ├─ RestaurantCardView.swift     # Image-forward card
   │  ├─ RestaurantDetailView.swift   # Hero + sticky "Order for Pickup" bar
   │  ├─ RestaurantMapView.swift      # Map with custom pins + place carousel
   │  ├─ CoverArtView.swift           # Generated per-restaurant cover art
   │  ├─ Components.swift             # Shared UI (chips, badges, favorite button)
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

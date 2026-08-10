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

- **Onboarding gate** — a calm, minimal location-permission screen that doubles
  as the "enable in Settings" prompt if access was denied.
- **Live nearby search** — real restaurants, cafés, bakeries, and more around
  your location, from **OpenStreetMap** (via the Overpass API).
- **Category chips that actually filter** — one-tap filters (Pizza, Sushi,
  Coffee, Mexican, Vegan…) each map to a real Overpass query.
- **Search by name** — type a restaurant or dish; searches OSM by name.
- **Clean, typographic list** — calm rows with a monochrome category thumbnail,
  name, and one line of metadata (cuisine · distance). No busy badges.
- **List + Map** — browse a distance-sorted list or a minimal map with clean
  pins and a single selected-place card.
- **Order direct** — a detail screen with a sticky **Order for Pickup** bar that
  opens the restaurant's own website (OSM `website` tag) in an in-app browser, so
  you order from the source with no marketplace markup.
- **Directions, Call, Website** — quiet secondary actions; Apple Maps directions,
  phone dialer, in-app browser.
- **Favorites** — heart a place from the detail screen; persists across launches.
- **No accounts, no API keys** — OpenStreetMap is open data, so the app runs out
  of the box with nothing to configure.

### Design

Deliberately minimal — closer to Blank Street / Kitchen Stories than a busy
delivery marketplace. Generous whitespace, a single restrained terracotta accent,
hairline dividers, and one clear action per screen. Because OpenStreetMap has no
food photography, thumbnails are calm monochrome tiles rather than invented
imagery — honest to the data.

---

## Tech stack

- **SwiftUI** (iOS 17+), MVVM architecture
- **OpenStreetMap / Overpass API** — live restaurant data over `URLSession`
  (no API key, no account, no billing)
- **MapKit** — `Map` for the map tab, directions, and the detail map card
- **CoreLocation** — one-shot "when in use" location for nearby search
- **SafariServices** — `SFSafariViewController` for in-app direct ordering

## Project layout

```
ios/
├─ RealBite.xcodeproj          # Xcode project (file-system-synchronized groups)
└─ RealBite/
   ├─ RealBiteApp.swift        # App entry point
   ├─ Models/
   │  ├─ Restaurant.swift      # Restaurant model + presentation helpers
   │  └─ FoodCategory.swift    # Filter chips → Overpass tag queries
   ├─ Services/
   │  ├─ LocationManager.swift         # CoreLocation wrapper
   │  ├─ OverpassService.swift         # OpenStreetMap nearby search + OSM→model
   │  └─ FavoritesStore.swift          # Persisted favorites (UserDefaults)
   ├─ ViewModels/
   │  └─ RestaurantListViewModel.swift # State + search + category orchestration
   ├─ Views/
   │  ├─ RootView.swift               # Onboarding gate → tab container
   │  ├─ OnboardingView.swift         # Minimal location-permission screen
   │  ├─ RestaurantListView.swift     # Chips + typographic list + states
   │  ├─ RestaurantRowView.swift      # Clean list row
   │  ├─ RestaurantDetailView.swift   # Detail + sticky "Order for Pickup" bar
   │  ├─ RestaurantMapView.swift      # Minimal map with dots + selected card
   │  ├─ Components.swift             # Shared UI (chip, thumbnail, favorite, Color+hex)
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
**Features ▸ Location ▸ Apple** (or **Custom Location…** in a city). On a device,
grant location permission when prompted. Results come from OpenStreetMap, so
coverage is richest in populated areas.

From the command line:

```bash
cd ios
xcodebuild -project RealBite.xcodeproj -scheme RealBite \
  -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## How ordering works

RealBite never places an order itself and adds no fees. When you tap **Order for
Pickup**, it opens the restaurant's own website (the OpenStreetMap `website` tag)
in an in-app Safari view. If a restaurant hasn't published an ordering page,
RealBite offers to search the web for their menu or to call them directly.

## Data & privacy

- Restaurant data comes from **OpenStreetMap** via the public Overpass API. The
  app sends only a coordinate + radius (and category/name filters) to look up
  nearby places — no account, no tracking, no API key.
- Coverage and detail (websites, phone, hours) depend on what the local OSM
  community has mapped; it's excellent in cities, thinner in rural areas.

## Notes & limitations

- Not every restaurant lists an online ordering URL; the app falls back to a web
  search or a phone call.
- `opening_hours` is shown as-is from OSM (e.g. `Mo-Fr 08:00-22:00`); the app
  doesn't compute a live "open now" status.
- Menus and prices aren't shown — RealBite is a discovery and hand-off tool, not
  an ordering backend.
- Pickup only, by design.

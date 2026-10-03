# GeoNavigation — Flutter Navigation Prototype

A production-grade, single-screen turn navigation mobile app built in Flutter for Android. The application renders OpenStreetMap tiles, obtains real-time device location via a custom native Kotlin FusedLocation bridge, queries the OSRM routing engine, and animates a vehicle along the path at constant speed with dynamic camera rotation and covered route progress tracking.

---

## Features

- **Native Android Location (No 3rd-party location plugins):**
  - Directly implemented in Kotlin via Google Play Services `FusedLocationProviderClient`.
  - Communicates with Flutter via `MethodChannel` (one-shot queries and permission requests) and `EventChannel` (continuous location updates).
  - Clean error code translation to strongly typed Dart exceptions (`LocationPermissionDenied`, `LocationServicesDisabled`, etc.).
- **Interactive OpenStreetMap Rendering:**
  - Powered by `flutter_map` (v7.0.2) + OpenStreetMap raster tile server.
  - Strict compliance with OpenStreetMap Tile Usage Policy (`userAgentPackageName` and visible attribution badge).
- **Contextual Permission Handling:**
  - Explanatory user prompt card before triggering the OS location permission dialog.
- **Debounced OSRM Driving Routes:**
  - Long-press destination selection with 600ms debouncing and monotonic request versioning to eliminate server flooding and race conditions.
  - Decodes Google-encoded polyline geometries into high-precision GPS coordinates.
- **Deterministic Pure-Dart Navigation Engine:**
  - Distance-based interpolation ensuring smooth, constant-speed vehicle travel regardless of route waypoint density.
  - Speed multipliers: `1x`, `2x`, and `5x`.
  - Start, Pause, Resume, and Reset controls.
- **Covered Route Visualization & Top-Down Car Pointer:**
  - Visual asset car pointer (`assets/icons/car_icon.png`).
  - As the vehicle travels, the traversed route dynamically turns light grey while remaining segments remain navigation blue.
- **Dynamic Camera Following & Direction-of-Travel Rotation:**
  - Camera rotates with the vehicle's heading so the forward road is always facing upward.
  - Automatically unfollows on manual user gestures and displays a **Recenter** button.
- **Arrival Modal Dialog:**
  - Presents a destination completion dialog with an "Okay" button upon arrival.
- **Flavors & Resource Safety:**
  - `dev` and `prod` product flavors.
  - Full Android lifecycle management via `WidgetsBindingObserver` (freezes animation ticker when backgrounded to prevent resource waste; resumes on foreground).

---

## Flutter & Package Versions

- **Flutter SDK:** `>=3.8.1` / Dart SDK `^3.8.1`
- **Dependencies:**
  - `get: ^4.6.6` — State management and dependency injection.
  - `flutter_map: ^7.0.2` — Interactive OpenStreetMap rendering.
  - `latlong2: ^0.9.1` — Geodesic coordinate models and distance primitives.
  - `http: ^1.2.2` — HTTP client for OSRM REST routing API.
  - `cupertino_icons: ^1.0.8` — Icon set.
- **Dev Dependencies:**
  - `flutter_lints: ^5.0.0`
  - `flutter_test:` (Flutter SDK)

### Android Requirements
- `minSdk`: **21** (Android 5.0 Lollipop)
- `compileSdk`: **35**
- `targetSdk`: **35**
- `play-services-location`: **21.3.0**

---

## How to Build and Run Each Flavor

The project is structured with two Android product flavors (`dev` and `prod`):

| Flavor | Application ID | App Name | Dev Banner |
|---|---|---|---|
| **dev** | `com.example.navtest.dev` | NavTest Dev | Enabled (`DEV` badge in top corner) |
| **prod** | `com.example.navtest` | NavTest | Disabled |

### Prerequisites
1. Ensure an Android device or emulator with Google Play Services is connected.
2. Run `flutter pub get`.

### Run Development Flavor
```bash
flutter run --flavor dev -t lib/main.dart
```

### Run Production Flavor
```bash
flutter run --flavor prod -t lib/main.dart
```

### Build APKs
```bash
# Debug APKs
flutter build apk --flavor dev --debug
flutter build apk --flavor prod --debug

# Release APKs
flutter build apk --flavor dev --release
flutter build apk --flavor prod --release
```

### iOS Support
> **Note on iOS:** The native location bridge (`LocationChannel.kt` and `LocationManager.kt`) is written specifically for Android using `FusedLocationProviderClient`. On iOS or desktop targets, the Dart channel layer gracefully returns a typed `LocationNotSupported` exception rather than crashing. To support iOS in production, implement `CoreLocation` (`CLLocationManager`) conforming to the same platform channel contract (`com.example.navtest/location` and `com.example.navtest/location_stream`).

---

## Testing & Quality Assurance

Run static analysis and the test suite:
```bash
# Static analysis (zero warnings/errors)
flutter analyze

# Unit tests
flutter test
```

---

## Known Limitations

1. **Public OSRM Demo Server:**
   - Routes are queried against the shared public demo endpoint (`https://router.project-osrm.org`). While requests are debounced by 600ms and guarded by request versioning, the public server may occasionally experience downtime or rate limiting.
2. **2D Tile Rendering vs 3D Tilt:**
   - `flutter_map` renders 2D raster tiles. While camera rotation (heading) is fully supported and active, 3D perspective pitch/tilt is not supported by raster OSM tiles.
3. **Android-Specific Native Bridge:**
   - Location streaming requires Google Play Services on Android. Non-GMS devices or iOS require alternative location implementations.
4. **Foreground Operation:**
   - Location streaming runs while the app is in the foreground. To conserve battery and respect user privacy, location updates are paused when backgrounded rather than keeping a persistent foreground service active.

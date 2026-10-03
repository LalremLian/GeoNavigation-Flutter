# Architecture & Technical Decisions

This document details the engineering decisions, tradeoffs, and architectural design choices behind the GeoNavigation project.

---

## 1. Architecture & State Management Choice

### Layered Clean Architecture
The codebase strictly separates concerns into 4 layers across feature boundaries:
1. **Presentation Layer (`features/navigation/presentation/`):**
   - Pure UI widgets (`MapView`, `ControlBar`, `CarMarker`, `RouteLayer`, `ArrivalDialog`, `PermissionPromptCard`).
   - `NavigationController` manages presentation state, ticker frames, camera movement, and delegates domain actions.
2. **Domain Layer (`features/navigation/domain/`):**
   - Entities (`LocationData`, `EngineState`, `RouteInfo`).
   - Pure Dart services: `NavigationEngine` (completely decoupled from Flutter, Widgets, or BuildContext) and `LocationService`.
3. **Data Layer (`features/navigation/data/`):**
   - Repositories (`RoutingRepository`), data sources (`OsrmService`), and low-level channel wrappers (`LocationChannelService`).
4. **Core Layer (`core/`):**
   - Reusable utilities (`BearingUtils`, `DistanceUtils`, `PolylineDecoder`), constants, and sealed error hierarchies (`AppError`).

### Why GetX?
- **Decoupled Business Logic:** GetX allows dependency injection (`Get.find<NavigationController>()`) and reactive state management (`Rx` and `Obx`) without requiring deep `BuildContext` drilling or boilerplate `ChangeNotifier` / `BlocProvider` trees.
- **Granular Widget Re-renders:** Observers (`Obx`) isolate rebuilds to only the widgets that depend on changing values (e.g., info panels updating remaining distance without rebuilding the entire map view).
- **Separation from Engine:** The navigation animation is driven by a `TickerProvider` passing delta time into a pure Dart `NavigationEngine`. GetX simply exposes the resulting immutable `EngineState` snapshot to the UI.

---

## 2. Flutter ↔ Native Location Bridge Design

Rather than relying on third-party plugins (such as `geolocator` or `location`), the native Android location layer was built from scratch in Kotlin using Google Play Services `FusedLocationProviderClient`.

### Platform Channel Architecture
- **`MethodChannel` (`com.example.navtest/location`):**
  - Used for discrete, one-shot RPC requests: `requestPermission`, `hasPermission`, `isLocationServiceEnabled`, `getCurrentLocation`, and `openAppSettings`.
- **`EventChannel` (`com.example.navtest/location_stream`):**
  - Used for continuous GPS updates.
  - Native location updates (`requestLocationUpdates`) begin **only when Dart attaches a stream listener** in `onListen`.
  - Native updates are immediately removed (`removeLocationUpdates`) as soon as Dart cancels the subscription in `onCancel`.

### Error Mapping
Native Android exceptions and error codes are translated into a strongly-typed Dart sealed error hierarchy (`AppError`):
- `PERMISSION_DENIED` $\rightarrow$ `LocationPermissionDenied`
- `PERMISSION_PERMANENTLY_DENIED` $\rightarrow$ `LocationPermissionPermanentlyDenied`
- `LOCATION_SERVICE_DISABLED` $\rightarrow$ `LocationServicesDisabled`
- `LOCATION_TIMEOUT` $\rightarrow$ `LocationTimeout`
- `LOCATION_UNAVAILABLE` $\rightarrow$ `LocationUnavailable`
- `NOT_SUPPORTED` $\rightarrow$ `LocationNotSupported`

This ensures that the presentation layer never interacts with untyped error strings or raw platform exception codes.

### Contextual Permission Timing
Permission is not demanded immediately on launch. The app first checks `hasPermission()` silently. If not granted, an explanatory rationale card (`PermissionPromptCard`) is presented to the user explaining why location is required before triggering the OS prompt.

---

## 3. Smooth Movement and Turning

The vehicle should move smoothly along the route instead of jumping from one route point to the next.

### Constant Speed
Route points are not always evenly spaced. A straight road may have points far apart, while a city turn may have many points close together. Moving one point at a time would therefore make the vehicle speed up and slow down.

To avoid this:
- `NavigationEngine` calculates the distance between all route points when the route is loaded.
- Each animation frame moves the vehicle by `speed × time`, so its speed stays consistent.
- The engine finds the correct part of the route and places the vehicle between its two nearest points.

### Smooth Bearing Changes
The vehicle's direction also changes smoothly. When the bearing changes from `359°` to `1°`, the vehicle turns 2° clockwise instead of rotating 358° in the wrong direction.

- `BearingUtils.shortestDelta()` chooses the shortest turn between two bearings.
- `NavigationController` gradually applies that turn, preventing sudden rotation and making corners look natural.

---

## 4. Flavor Configuration

Android flavors are configured directly in `android/app/build.gradle.kts`:
- **`dev`**:
  - `applicationId`: `com.example.navtest.dev`
  - App Name: `NavTest Dev`
  - Shows visual `DEV` badge overlay in top corner.
- **`prod`**:
  - `applicationId`: `com.example.navtest`
  - App Name: `NavTest`
  - Standard production environment without banners.

Flavor values (`ROUTING_BASE_URL`, `FLAVOR_NAME`) are injected at compile time via `BuildConfig` and passed to Dart at startup through `AppConfig.initialise()`.

---

## 5. Production Readiness & Scalability

Before shipping this implementation to production at commercial scale, the following improvements would be prioritized:

1. **Routing Server & API Costs:**
   - The public OSRM server is a shared demo instance without SLA guarantees.
   - *Production Solution:* Deploy dedicated OSRM instances on AWS ECS/Kubernetes behind Cloudflare, or integrate enterprise map providers (e.g., Mapbox Directions API, Google Routes API, or Valhalla) with API key rotation, request signing, and Redis response caching.
2. **Request Throttling & Debouncing:**
   - 600ms debouncing and version checks are currently active to prevent server hammering. At scale, client-side rate limiters and offline route caching (SQLite/Hive) would prevent redundant queries for identical origin/destination pairs.
3. **Battery & Power Consumption:**
   - `FusedLocationProviderClient` currently requests high-accuracy balanced updates. In production:
     - Throttle location intervals when the vehicle is stationary (detected via `ActivityRecognitionClient`).
     - Increase `displacementFilter` (e.g. only emit fixes if the user moves $>5$ meters).
4. **Background Location & Battery Constraints:**
   - Currently, navigation pauses when the app goes into the background to avoid battery drain.
   - For a real navigation app, implement an Android **Foreground Service** with a persistent notification (`startForegroundService`) and `ACCESS_BACKGROUND_LOCATION` permission so navigation voice cues and tracking continue when the screen is locked.

---

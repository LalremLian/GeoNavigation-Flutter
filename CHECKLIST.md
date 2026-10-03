# Requirement Checklist

| Requirement | Implementation |
|---|---|
| Native location without third-party location plugins | `android/app/src/main/kotlin/com/example/navtest/location/LocationManager.kt` |
| FusedLocationProviderClient | `LocationManager.kt` |
| MethodChannel and EventChannel | `LocationChannel.kt`, `location_channel_service.dart` |
| Native stream cancellation | `LocationChannel.onCancel`, `LocationManager.stopLocationUpdates` |
| OSM map and attribution | `presentation/widgets/map_view.dart` |
| OSRM `lon,lat` coordinates | `data/services/osrm_service.dart` |
| Polyline decoding | `core/utils/polyline_decoder.dart` |
| Shortest-angle bearing | `core/utils/bearing_utils.dart` |
| Camera unfollow and recenter | `navigation_controller.dart`, `map_view.dart`, `recenter_button.dart` |
| Navigation controls and speed | `control_bar.dart`, `navigation_controller.dart` |
| Live remaining distance/duration | `navigation_engine.dart`, `info_panel.dart` |
| Lifecycle and resource cleanup | `navigation_controller.dart`, `LocationChannel.kt` |
| Dev/prod flavors | `android/app/build.gradle.kts`, `dev_banner.dart` |
| Engine, bearing and decoder tests | `test/navigation`, `test/core` |

## Verification commands

```bash
flutter analyze
flutter test
flutter build apk --flavor dev --debug
flutter build apk --flavor prod --debug
```

The repository contains no imports of `geolocator`, `location`,
`permission_handler`, Google Maps or Mapbox.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/navigation_controller.dart';
import 'car_marker.dart';
import 'route_layer.dart';

/// Full-screen map widget backed by flutter_map + OpenStreetMap.
///
/// Rendering responsibilities:
///   - OSM tile layer with correct attribution
///   - Current location marker (blue dot)
///   - Destination marker (red pin)
///   - Route polyline (via [RouteLayer])
///   - Animated car marker (via [CarMarker])
///   - Long-press → destination selection
///   - Map gesture detection → camera unfollow (Phase 9)
///
/// No routing, interpolation or bearing mathematics live here.
class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  late final NavigationController _navController;

  @override
  void initState() {
    super.initState();
    _navController = Get.find<NavigationController>();
    // Inject the MapController so the NavigationController can move the camera
    _navController.attachMapController(_mapController);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(0, 0),
        initialZoom: 2, // world view until GPS fix arrives
        onLongPress: (tapPosition, point) {
          _navController.onMapLongPress(point);
        },
        onMapEvent: (event) {
          // Detect any user-initiated map movement and stop camera following.
          // We check for gesture sources — anything that is NOT a programmatic
          // move from the MapController, fitCamera, or size changes.
          if (event is MapEventMove) {
            switch (event.source) {
              case MapEventSource.mapController:
              case MapEventSource.fitCamera:
              case MapEventSource.nonRotatedSizeChange:
              case MapEventSource.interactiveFlagsChanged:
                // Programmatic — do not interrupt camera following
                break;
              default:
                // User gesture (drag, fling, pinch, scroll wheel, etc.)
                _navController.onUserMapGesture();
            }
          }
        },
      ),
      children: [
        // ---------------------------------------------------------------
        // OSM tile layer — attribution required by OSM tile usage policy
        // ---------------------------------------------------------------
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.navtest',
          maxZoom: 19,
        ),

        // ---------------------------------------------------------------
        // Route polyline
        // ---------------------------------------------------------------
        const RouteLayer(),

        // ---------------------------------------------------------------
        // Location + destination markers
        // ---------------------------------------------------------------
        Obx(() {
          final markers = <Marker>[];

          // Current location — blue pulsing dot style
          final loc = _navController.currentLocation.value;
          if (loc != null) {
            markers.add(
              Marker(
                point: LatLng(loc.latitude, loc.longitude),
                width: 22,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.blue,
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Destination pin
          final dest = _navController.destination.value;
          if (dest != null) {
            markers.add(
              Marker(
                point: dest,
                width: 36,
                height: 44,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            );
          }

          return MarkerLayer(markers: markers);
        }),

        // ---------------------------------------------------------------
        // Animated car
        // ---------------------------------------------------------------
        const CarMarker(),

        // ---------------------------------------------------------------
        // OSM attribution — required by OSM tile usage policy
        // ---------------------------------------------------------------
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('© OpenStreetMap contributors'),
          ],
        ),

        // ---------------------------------------------------------------
        // Long-press hint — shown until the first destination is set
        // ---------------------------------------------------------------
        Obx(() {
          final hasDest = _navController.destination.value != null;
          final hasLocation = _navController.currentLocation.value != null;
          if (hasDest || !hasLocation) return const SizedBox.shrink();
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 160),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Long-press on the map to set a destination',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

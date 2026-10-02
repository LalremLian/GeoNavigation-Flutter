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
///   - Current location marker
///   - Destination marker
///   - Route polyline (via [RouteLayer])
///   - Animated car marker (via [CarMarker])
///   - Long-press → destination selection
///   - Map gesture detection → camera unfollow
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
    // TODO(phase9): pass _mapController to NavigationController
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
        initialZoom: 13,
        onLongPress: (tapPosition, point) {
          _navController.onMapLongPress(point);
        },
        onMapEvent: (event) {
          // TODO(phase9): detect gesture-initiated moves
        },
      ),
      children: [
        // OSM tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.navtest',
        ),

        // Route polyline
        const RouteLayer(),

        // Markers: current location, destination, car
        Obx(() {
          final markers = <Marker>[];

          // Current location blue dot
          final loc = _navController.currentLocation.value;
          if (loc != null) {
            markers.add(
              Marker(
                point: LatLng(loc.latitude, loc.longitude),
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
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
                width: 32,
                height: 40,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 36,
                ),
              ),
            );
          }

          return MarkerLayer(markers: markers);
        }),

        // Animated car
        const CarMarker(),

        // OSM attribution — required by OSM tile usage policy
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('© OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}

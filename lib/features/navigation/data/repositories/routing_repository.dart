import 'package:latlong2/latlong.dart';

import '../../../../core/errors/routing_errors.dart';
import '../../../../core/utils/polyline_decoder.dart';
import '../models/route_model.dart';
import '../services/osrm_service.dart';

class RoutingRepository {
  RoutingRepository({required OsrmService osrmService}) : _osrmService = osrmService;

  final OsrmService _osrmService;

  Future<RouteModel> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // Fetch from OSRM
    final response = await _osrmService.fetchRoute(
      originLat: origin.latitude,
      originLng: origin.longitude,
      destLat: destination.latitude,
      destLng: destination.longitude,
    );

    if (!response.isOk || response.routes.isEmpty) {
      throw const NoRouteFound();
    }

    // Take the best route (index 0 — OSRM orders by best first)
    final best = response.routes.first;

    // Decode the encoded polyline geometry
    final points = PolylineDecoder.decode(best.geometry);

    // Validate: must have at least 2 usable points
    if (points.length < 2) {
      throw const InvalidRoute('Decoded route has fewer than 2 points');
    }

    // Validate: no NaN or Infinity in coordinates
    for (final pt in points) {
      if (!pt.latitude.isFinite || !pt.longitude.isFinite) {
        throw const InvalidRoute('Route contains non-finite coordinates');
      }
    }

    // Validate: must have non-zero distance
    if (!best.distanceMeters.isFinite ||
        !best.durationSeconds.isFinite ||
        best.distanceMeters <= 0 ||
        best.durationSeconds < 0) {
      throw const InvalidRoute('Route has zero distance');
    }

    return RouteModel(
      points: points,
      totalDistanceMeters: best.distanceMeters,
      totalDurationSeconds: best.durationSeconds,
    );
  }

  void dispose() {
    _osrmService.dispose();
  }
}

import 'package:latlong2/latlong.dart';

import '../models/route_model.dart';
import '../services/osrm_service.dart';

/// Orchestrates [OsrmService] calls and converts raw responses into
/// validated [RouteModel] objects.
///
/// This is the single entry-point for routing from the rest of the app.
/// [NavigationController] calls this; nothing above it touches HTTP.
class RoutingRepository {
  RoutingRepository({required OsrmService osrmService})
      : _osrmService = osrmService;

  final OsrmService _osrmService;

  /// Fetches and returns a validated [RouteModel].
  ///
  /// Stale-request protection: the caller passes a [requestVersion].
  /// If the returned version does not match [requestVersion], the caller
  /// should discard the result. (Implemented in Phase 5.)
  ///
  /// Throws typed [AppError] subclasses on failure.
  Future<RouteModel> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // TODO(phase5): implement
    throw UnimplementedError('Implemented in Phase 5');
  }

  void dispose() {
    _osrmService.dispose();
  }
}

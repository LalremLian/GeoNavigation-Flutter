import 'package:http/http.dart' as http;

import '../models/osrm_response.dart';

/// Makes raw HTTP calls to the OSRM routing API.
///
/// Knows about HTTP and JSON only — no business logic.
/// The [RoutingRepository] calls this and converts the response to a [RouteModel].
class OsrmService {
  OsrmService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  // ignore: unused_field — used in Phase 5 implementation
  static const Duration _timeout = Duration(seconds: 10);

  /// Fetches a driving route between [origin] and [destination].
  ///
  /// Coordinates must be [LatLng]-style (lat, lng) but are sent to OSRM
  /// as lng,lat (OSRM uses GeoJSON coordinate order).
  ///
  /// Throws typed [AppError] subclasses on failure.
  Future<OsrmResponse> fetchRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    // TODO(phase5): implement — stub compiles cleanly
    throw UnimplementedError('Implemented in Phase 5');
  }

  /// Builds the OSRM route URL.
  /// Visible for testing.
  Uri buildRouteUri({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) {
    // OSRM expects longitude,latitude order
    final coords = '$originLng,$originLat;$destLng,$destLat';
    return Uri.parse(
      '$baseUrl/route/v1/driving/$coords'
      '?overview=full&geometries=polyline',
    );
  }

  void dispose() {
    _client.close();
  }
}

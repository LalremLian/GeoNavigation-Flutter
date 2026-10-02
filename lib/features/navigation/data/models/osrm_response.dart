/// Raw OSRM JSON → typed response object.
///
/// Only used inside [OsrmService] to parse the HTTP response before
/// it is converted into a [RouteModel].
class OsrmResponse {
  const OsrmResponse({
    required this.code,
    required this.routes,
  });

  factory OsrmResponse.fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String? ?? '';
    final rawRoutes = json['routes'] as List<dynamic>? ?? [];

    final routes = rawRoutes
        .whereType<Map<String, dynamic>>()
        .map(OsrmRoute.fromJson)
        .toList();

    return OsrmResponse(code: code, routes: routes);
  }

  /// OSRM status code — "Ok" means success.
  final String code;
  final List<OsrmRoute> routes;

  bool get isOk => code == 'Ok';
}

class OsrmRoute {
  const OsrmRoute({
    required this.geometry,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory OsrmRoute.fromJson(Map<String, dynamic> json) {
    return OsrmRoute(
      geometry: json['geometry'] as String? ?? '',
      distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (json['duration'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Encoded polyline string (Google format, precision 1e-5).
  final String geometry;
  final double distanceMeters;
  final double durationSeconds;
}

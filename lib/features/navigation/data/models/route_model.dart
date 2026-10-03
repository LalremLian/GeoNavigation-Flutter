import 'package:latlong2/latlong.dart';

class RouteModel {
  const RouteModel({
    required this.points,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
  });

  /// Ordered list of coordinates that form the driving route.
  final List<LatLng> points;

  /// Total route length in metres.
  final double totalDistanceMeters;

  /// Estimated driving duration in seconds (from OSRM).
  final double totalDurationSeconds;

  bool get isEmpty => points.isEmpty;

  @override
  String toString() =>
      'RouteModel(points: ${points.length}, '
      'distance: ${totalDistanceMeters.toStringAsFixed(0)}m, '
      'duration: ${totalDurationSeconds.toStringAsFixed(0)}s)';
}

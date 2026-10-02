import 'package:latlong2/latlong.dart';

/// Snapshot of the [NavigationEngine] state at a single animation frame.
///
/// Immutable — the engine produces a new instance every tick.
class EngineState {
  const EngineState({
    required this.position,
    required this.bearingDegrees,
    required this.traveledDistanceMeters,
    required this.remainingDistanceMeters,
    required this.remainingDurationSeconds,
    required this.progress,
    required this.isCompleted,
  });

  /// Car's current interpolated position on the route.
  final LatLng position;

  /// Car's current heading in degrees [0, 360).
  final double bearingDegrees;

  /// Distance covered so far in metres.
  final double traveledDistanceMeters;

  /// Distance remaining to destination in metres.
  final double remainingDistanceMeters;

  /// Estimated time to destination in seconds at the current speed.
  final double remainingDurationSeconds;

  /// Fractional progress along the route [0.0, 1.0].
  final double progress;

  /// True once the car has reached the end of the route.
  final bool isCompleted;

  /// A zeroed-out state for use before a route is loaded.
  static const EngineState empty = EngineState(
    position: LatLng(0, 0),
    bearingDegrees: 0,
    traveledDistanceMeters: 0,
    remainingDistanceMeters: 0,
    remainingDurationSeconds: 0,
    progress: 0,
    isCompleted: false,
  );

  @override
  String toString() =>
      'EngineState(progress: ${(progress * 100).toStringAsFixed(1)}%, '
      'remaining: ${remainingDistanceMeters.toStringAsFixed(0)}m, '
      'completed: $isCompleted)';
}

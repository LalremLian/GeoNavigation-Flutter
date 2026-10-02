import '../../data/models/route_model.dart';
import '../entities/engine_state.dart';

/// Pure-Dart navigation engine.
///
/// Responsibilities:
///   - Distance-based position interpolation (constant speed regardless of
///     route-point density).
///   - Bearing calculation with shortest-angle interpolation.
///   - Remaining distance and duration tracking.
///   - Route completion detection.
///
/// Constraints (strictly enforced):
///   - NO Flutter widgets, BuildContext, flutter_map, MapController, GetX.
///   - All public methods are synchronous and side-effect free.
///   - Safe to instantiate and call in pure-Dart unit tests.
///
/// Implemented fully in Phase 6.
class NavigationEngine {
  NavigationEngine();

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Base speed in metres/second (≈ 50 km/h).
  static const double baseSpeedMps = 13.89;

  double _speedMultiplier = 1.0;

  // ---------------------------------------------------------------------------
  // Route state
  // ---------------------------------------------------------------------------

  RouteModel? _route;

  /// Pre-computed cumulative distances at each route point (metres).
  /// Index 0 is always 0; index n is total distance to point n.
  // ignore: prefer_final_fields, unused_field — populated in Phase 6
  List<double> _cumulativeDistances = [];

  // ignore: prefer_final_fields — set in Phase 6
  double _totalDistanceMeters = 0;

  // ---------------------------------------------------------------------------
  // Progress state
  // ---------------------------------------------------------------------------

  double _traveledMeters = 0;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Loads [route] and resets progress to the beginning.
  void loadRoute(RouteModel route) {
    // TODO(phase6): implement
    _route = route;
    _traveledMeters = 0;
  }

  /// Advances the car by [deltaTime] at the current speed.
  ///
  /// Returns the new [EngineState]. Safe to call on every animation frame.
  EngineState advance(Duration deltaTime) {
    // TODO(phase6): implement
    return EngineState.empty;
  }

  /// Sets the speed multiplier (1, 2 or 5).
  ///
  /// Does NOT reset progress — the car continues from the same position
  /// at the new speed.
  void setSpeedMultiplier(double multiplier) {
    assert(multiplier > 0, 'Speed multiplier must be positive');
    _speedMultiplier = multiplier;
  }

  /// Returns the effective speed in metres/second.
  double get effectiveSpeed => baseSpeedMps * _speedMultiplier;

  /// Resets progress to the beginning of the loaded route.
  void reset() {
    _traveledMeters = 0;
  }

  /// True after the car has reached the end of the route.
  bool get isCompleted {
    if (_route == null || _route!.isEmpty) return true;
    return _traveledMeters >= _totalDistanceMeters;
  }

  /// True if a route is loaded and has at least 2 points.
  bool get hasRoute =>
      _route != null &&
      _route!.points.length >= 2 &&
      _totalDistanceMeters > 0;
}

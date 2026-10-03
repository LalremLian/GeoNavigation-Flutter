import 'package:latlong2/latlong.dart';

import '../../../../core/utils/bearing_utils.dart';
import '../../../../core/utils/distance_utils.dart';
import '../../data/models/route_model.dart';
import '../entities/engine_state.dart';

/// Pure-Dart navigation engine.
///
/// Responsibilities:
///   - Pre-computes cumulative segment distances for O(log n) lookups
///   - Distance-based interpolation: car moves at constant speed in m/s,
///     completely independent of route-point density
///   - Bearing calculation with shortest-angle interpolation
///   - Remaining distance and duration tracking
///   - Route completion detection
///
/// Constraints (strictly enforced — required for unit testability):
///   - NO Flutter widgets, BuildContext, flutter_map, MapController, GetX
///   - All public methods are synchronous
///   - Safe to instantiate and call in pure-Dart unit tests
class NavigationEngine {
  NavigationEngine();

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Base driving speed in metres/second (≈ 50 km/h).
  static const double baseSpeedMps = 13.89;

  double _speedMultiplier = 1.0;

  // ---------------------------------------------------------------------------
  // Route state (set by loadRoute)
  // ---------------------------------------------------------------------------

  List<LatLng> _points = const [];

  /// Cumulative distance from point[0] to point[i], in metres.
  /// _cumDist[0] == 0, _cumDist[n-1] == totalDistanceMeters.
  List<double> _cumDist = const [];

  double _totalDistanceMeters = 0;

  // ---------------------------------------------------------------------------
  // Progress state
  // ---------------------------------------------------------------------------

  double _traveledMeters = 0;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Loads [route] and resets progress to the beginning.
  ///
  /// Handles:
  ///   - Empty route
  ///   - Single-point route
  ///   - Duplicate / zero-distance segments (skipped in distance calc)
  ///   - Non-finite coordinates (segment treated as zero-distance)
  void loadRoute(RouteModel route) {
    _points = route.points
        .where((point) =>
            point.latitude.isFinite && point.longitude.isFinite)
        .toList(growable: false);
    _traveledMeters = 0;
    _cumDist = _buildCumulativeDistances(_points);
    _totalDistanceMeters = _cumDist.isNotEmpty ? _cumDist.last : 0;
  }

  /// Advances the car by [deltaTime] at the current effective speed.
  ///
  /// Returns a fresh [EngineState]. Safe to call on every animation frame.
  EngineState advance(Duration deltaTime) {
    // Edge cases: no route or already complete
    if (_points.isEmpty) {
      return const EngineState(
        position: LatLng(0, 0),
        bearingDegrees: 0,
        traveledDistanceMeters: 0,
        remainingDistanceMeters: 0,
        remainingDurationSeconds: 0,
        progress: 1,
        isCompleted: true,
      );
    }
    if (_points.length == 1) {
      return EngineState(
        position: _points.first,
        bearingDegrees: 0,
        traveledDistanceMeters: 0,
        remainingDistanceMeters: 0,
        remainingDurationSeconds: 0,
        progress: 1,
        isCompleted: true,
      );
    }

    // Advance by distance = speed × time
    final deltaSec = deltaTime.inMicroseconds / 1000000.0;
    _traveledMeters =
        (_traveledMeters + effectiveSpeed * deltaSec)
            .clamp(0, _totalDistanceMeters);

    return _buildState();
  }

  /// Sets the speed multiplier (1, 2 or 5).
  /// Does NOT reset progress — car continues from the same position.
  void setSpeedMultiplier(double multiplier) {
    if (!multiplier.isFinite || multiplier <= 0) {
      _speedMultiplier = 1.0;
      return;
    }
    _speedMultiplier = multiplier;
  }

  /// Resets progress to the beginning of the loaded route.
  void reset() {
    _traveledMeters = 0;
  }

  /// True after the car has reached the end of the route.
  bool get isCompleted {
    if (_points.isEmpty || _points.length == 1) return true;
    return _traveledMeters >= _totalDistanceMeters;
  }

  /// True if a route is loaded with at least 2 points and non-zero distance.
  bool get hasRoute =>
      _points.length >= 2 && _totalDistanceMeters > 0;

  /// Effective speed in metres/second.
  double get effectiveSpeed => baseSpeedMps * _speedMultiplier;

  // ---------------------------------------------------------------------------
  // Internal: cumulative distance table
  // ---------------------------------------------------------------------------

  static List<double> _buildCumulativeDistances(List<LatLng> points) {
    if (points.isEmpty) return const [];
    if (points.length == 1) return [0.0];

    final cum = List<double>.filled(points.length, 0);
    for (int i = 1; i < points.length; i++) {
      final segDist = _safeDistance(points[i - 1], points[i]);
      cum[i] = cum[i - 1] + segDist;
    }
    return cum;
  }

  /// Haversine distance guarded against non-finite coordinates.
  static double _safeDistance(LatLng a, LatLng b) {
    if (!a.latitude.isFinite ||
        !a.longitude.isFinite ||
        !b.latitude.isFinite ||
        !b.longitude.isFinite) {
      return 0;
    }
    final d = DistanceUtils.haversine(
      lat1: a.latitude,
      lng1: a.longitude,
      lat2: b.latitude,
      lng2: b.longitude,
    );
    // Guard against NaN / Infinity from haversine (e.g. duplicate points)
    return d.isFinite ? d : 0;
  }

  // ---------------------------------------------------------------------------
  // Internal: build EngineState from current _traveledMeters
  // ---------------------------------------------------------------------------

  EngineState _buildState() {
    // Binary search: find the segment that contains _traveledMeters
    final segIdx = _findSegmentIndex(_traveledMeters);
    final segStart = _cumDist[segIdx];
    final segEnd = _cumDist[segIdx + 1];
    final segLen = segEnd - segStart;

    final LatLng position;
    final double bearing;

    if (segLen <= 0) {
      // Zero-distance segment (duplicate points) — sit at the start point
      position = _points[segIdx];
      bearing = _bearingToNext(segIdx);
    } else {
      // Linear interpolation within the segment
      final t = (_traveledMeters - segStart) / segLen;
      position = _interpolate(_points[segIdx], _points[segIdx + 1], t);
      bearing = BearingUtils.bearing(
        fromLat: _points[segIdx].latitude,
        fromLng: _points[segIdx].longitude,
        toLat: _points[segIdx + 1].latitude,
        toLng: _points[segIdx + 1].longitude,
      );
    }

    final remaining = (_totalDistanceMeters - _traveledMeters)
        .clamp(0.0, _totalDistanceMeters);
    final progress = _totalDistanceMeters > 0
        ? (_traveledMeters / _totalDistanceMeters).clamp(0.0, 1.0)
        : 1.0;
    final remainingDuration =
        effectiveSpeed > 0 ? remaining / effectiveSpeed : 0.0;
    final completed = _traveledMeters >= _totalDistanceMeters;

    return EngineState(
      position: position,
      bearingDegrees: bearing,
      traveledDistanceMeters: _traveledMeters,
      remainingDistanceMeters: remaining.toDouble(),
      remainingDurationSeconds: remainingDuration,
      progress: progress,
      isCompleted: completed,
    );
  }

  // ---------------------------------------------------------------------------
  // Internal: binary search for segment index
  // ---------------------------------------------------------------------------

  /// Returns index i such that _cumDist[i] <= traveled < _cumDist[i+1].
  /// Clamps to the last valid segment.
  int _findSegmentIndex(double traveled) {
    // Handle completion
    if (traveled >= _totalDistanceMeters) {
      return _points.length - 2;
    }

    int lo = 0;
    int hi = _cumDist.length - 2; // last valid segment start index

    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (_cumDist[mid] <= traveled) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  // ---------------------------------------------------------------------------
  // Internal: interpolation + bearing helpers
  // ---------------------------------------------------------------------------

  static LatLng _interpolate(LatLng a, LatLng b, double t) {
    // Clamp t to avoid floating-point overshoot
    final tc = t.clamp(0.0, 1.0);
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * tc,
      a.longitude + (b.longitude - a.longitude) * tc,
    );
  }

  /// Returns bearing toward the next non-duplicate point from [idx].
  double _bearingToNext(int idx) {
    for (int i = idx + 1; i < _points.length; i++) {
      final d = _safeDistance(_points[idx], _points[i]);
      if (d > 0) {
        return BearingUtils.bearing(
          fromLat: _points[idx].latitude,
          fromLng: _points[idx].longitude,
          toLat: _points[i].latitude,
          toLng: _points[i].longitude,
        );
      }
    }
    return 0; // no non-duplicate next point found
  }
}

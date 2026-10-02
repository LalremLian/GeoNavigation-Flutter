import 'dart:math' as math;

/// Haversine distance calculations.
///
/// No Flutter/GetX dependencies — safe for pure Dart unit tests.
abstract final class DistanceUtils {
  static const double _earthRadiusMeters = 6371000.0;

  /// Returns the great-circle distance in **metres** between two coordinates.
  static double haversine({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  /// Formats a distance in metres to a human-readable string.
  /// < 1 km → "450 m", ≥ 1 km → "3.2 km"
  static String format(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Formats a duration in seconds to "Xh Ym" or "Y min".
  static String formatDuration(double seconds) {
    final total = seconds.round();
    if (total < 60) return '< 1 min';
    final minutes = total ~/ 60;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}

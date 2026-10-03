import 'dart:math' as math;

/// Pure bearing/angle utilities.
abstract final class BearingUtils {
  /// Calculates the initial bearing (forward azimuth) in degrees [0, 360)
  /// from point [fromLat]/[fromLng] to point [toLat]/[toLng].
  ///
  /// Uses the spherical law of cosines formula.
  static double bearing({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final dLng = _toRad(toLng - fromLng);
    final lat1 = _toRad(fromLat);
    final lat2 = _toRad(toLat);

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearing = math.atan2(y, x);
    return (_toDeg(bearing) + 360) % 360;
  }

  /// Returns the shortest angular difference to rotate [from] to [to].
  static double shortestDelta(double from, double to) {
    double delta = (to - from) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return delta;
  }

  /// Normalises any angle to [0, 360).
  static double normalise(double degrees) => (degrees % 360 + 360) % 360;

  /// Linearly interpolates bearing using the shortest angular path.
  static double interpolate(double from, double to, double t) {
    return normalise(from + shortestDelta(from, to) * t);
  }

  static double _toRad(double deg) => deg * math.pi / 180;
  static double _toDeg(double rad) => rad * 180 / math.pi;
}

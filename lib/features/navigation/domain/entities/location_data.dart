
class LocationData {
  const LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.bearing,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;

  /// Horizontal accuracy in metres (null if unavailable).
  final double? accuracy;

  /// Speed in metres/second (null if unavailable).
  final double? speed;

  /// Device heading in degrees [0, 360) (null if unavailable).
  final double? bearing;

  final DateTime timestamp;

  @override
  String toString() =>
      'LocationData(lat: $latitude, lng: $longitude, '
      'accuracy: ${accuracy?.toStringAsFixed(1)}m)';
}

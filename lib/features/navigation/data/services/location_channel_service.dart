import 'package:flutter/services.dart';

import '../../../../core/constants/channel_constants.dart';
import '../../../../core/errors/location_errors.dart';
import '../../domain/entities/location_data.dart';

/// Low-level bridge between Dart and the native Android location channels.
///
/// This is the ONLY class that directly touches [MethodChannel] or
/// [EventChannel] for location. Everything above this layer uses
/// [LocationService] which wraps this class.
///
/// Implemented in Phase 2 — stub exists so imports compile.
class LocationChannelService {
  LocationChannelService()
      : _methodChannel = const MethodChannel(ChannelConstants.locationMethod),
        _eventChannel = const EventChannel(ChannelConstants.locationStream);

  // ignore: unused_field — used in Phase 2 implementation
  final MethodChannel _methodChannel;
  // ignore: unused_field — used in Phase 2 implementation
  final EventChannel _eventChannel;

  // ---------------------------------------------------------------------------
  // One-shot commands via MethodChannel
  // ---------------------------------------------------------------------------

  /// Asks Android to show the permission rationale dialog if needed,
  /// then request ACCESS_FINE_LOCATION.
  ///
  /// Throws a typed [AppError] on denial.
  Future<void> requestPermission() async {
    // TODO(phase2): implement
    throw UnimplementedError('Implemented in Phase 2');
  }

  /// Returns true if ACCESS_FINE_LOCATION is currently granted.
  Future<bool> hasPermission() async {
    // TODO(phase2): implement
    throw UnimplementedError('Implemented in Phase 2');
  }

  /// Returns true if the device GPS / network provider is enabled.
  Future<bool> isLocationServiceEnabled() async {
    // TODO(phase2): implement
    throw UnimplementedError('Implemented in Phase 2');
  }

  /// Requests a single, fresh location fix with a native timeout.
  ///
  /// Throws [LocationTimeout] if no fix arrives in time.
  Future<LocationData> getCurrentLocation() async {
    // TODO(phase2): implement
    throw UnimplementedError('Implemented in Phase 2');
  }

  /// Opens the system app-settings screen so the user can grant
  /// permanently-denied permissions.
  Future<void> openAppSettings() async {
    // TODO(phase2): implement
    throw UnimplementedError('Implemented in Phase 2');
  }

  // ---------------------------------------------------------------------------
  // Continuous stream via EventChannel
  // ---------------------------------------------------------------------------

  /// Returns a broadcast stream of location updates.
  ///
  /// The native side starts FusedLocation updates when the first listener
  /// subscribes and stops them when the last listener cancels.
  Stream<LocationData> locationStream() {
    // TODO(phase2): implement
    return const Stream.empty();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Converts a raw channel map from the native side into a [LocationData].
  /// Exposed for testing.
  static LocationData mapToLocationData(Map<Object?, Object?> raw) {
    return LocationData(
      latitude: (raw['lat'] as num).toDouble(),
      longitude: (raw['lng'] as num).toDouble(),
      accuracy: (raw['accuracy'] as num?)?.toDouble(),
      speed: (raw['speed'] as num?)?.toDouble(),
      bearing: (raw['bearing'] as num?)?.toDouble(),
      timestamp: raw['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(raw['timestamp'] as int)
          : DateTime.now(),
    );
  }

  /// Maps a [PlatformException] code to a typed location error and rethrows.
  static Never throwMapped(PlatformException e) {
    throw locationErrorFromCode(e.code, e.message);
  }
}

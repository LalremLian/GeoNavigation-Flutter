import 'dart:async';

import 'package:flutter/services.dart';

import '../../../../core/constants/channel_constants.dart';
import '../../../../core/errors/location_errors.dart';
import '../../domain/entities/location_data.dart';

/// Low-level bridge between Dart and the native Android location channels.
///
/// This is the ONLY class in the codebase that directly references
/// [MethodChannel] or [EventChannel] for location data.
/// Every call above this layer goes through [LocationService].
///
/// Platform contract (must match LocationChannel.kt exactly):
///   MethodChannel : com.example.navtest/location
///   EventChannel  : com.example.navtest/location_stream
///
/// On unsupported platforms (iOS not yet implemented, web, desktop)
/// every method returns a [LocationNotSupported] error rather than crashing.
class LocationChannelService {
  LocationChannelService()
      : _methodChannel = const MethodChannel(ChannelConstants.locationMethod),
        _eventChannel = const EventChannel(ChannelConstants.locationStream);

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  /// Triggers the OS permission dialog for ACCESS_FINE_LOCATION.
  ///
  /// Completes normally if granted.
  /// Throws [LocationPermissionDenied] or [LocationPermissionPermanentlyDenied].
  Future<void> requestPermission() async {
    try {
      await _methodChannel.invokeMethod<String>('requestPermission');
      // Any non-exception return means granted
    } on PlatformException catch (e) {
      _throwMapped(e);
    } on MissingPluginException {
      throw const LocationNotSupported();
    }
  }

  /// Returns true if ACCESS_FINE_LOCATION is currently granted.
  Future<bool> hasPermission() async {
    try {
      final result = await _methodChannel.invokeMethod<String>('checkPermission');
      return result == 'granted';
    } on PlatformException catch (e) {
      _throwMapped(e);
    } on MissingPluginException {
      throw const LocationNotSupported();
    }
  }

  /// Returns true if the device GPS / network location provider is on.
  Future<bool> isLocationServiceEnabled() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('isLocationServiceEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      _throwMapped(e);
    } on MissingPluginException {
      throw const LocationNotSupported();
    }
  }

  // ---------------------------------------------------------------------------
  // Single fix
  // ---------------------------------------------------------------------------

  /// Requests a fresh location fix from the native side.
  ///
  /// Throws a typed [AppError] on any failure.
  Future<LocationData> getCurrentLocation() async {
    try {
      final raw = await _methodChannel
          .invokeMapMethod<Object?, Object?>('getCurrentLocation');
      if (raw == null) throw const LocationUnavailable('No data returned');
      return _mapToLocationData(raw);
    } on PlatformException catch (e) {
      _throwMapped(e);
    } on MissingPluginException {
      throw const LocationNotSupported();
    }
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// Opens the system app-settings screen so the user can re-enable
  /// a permanently-denied permission.
  Future<void> openAppSettings() async {
    try {
      await _methodChannel.invokeMethod<void>('openAppSettings');
    } on PlatformException catch (e) {
      _throwMapped(e);
    } on MissingPluginException {
      throw const LocationNotSupported();
    }
  }

  // ---------------------------------------------------------------------------
  // Continuous stream
  // ---------------------------------------------------------------------------

  /// Returns a broadcast stream of location updates.
  ///
  /// The native side starts [FusedLocationProviderClient] updates when the
  /// first subscriber listens and stops them when the subscription is cancelled.
  ///
  /// Emits typed [AppError] subclasses via [addError] on failure — callers
  /// can distinguish them with an `onError` handler or `.handleError()`.
  Stream<LocationData> locationStream() {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) {
          // EventChannel delivers a Map<Object?, Object?> from Kotlin
          final raw = Map<Object?, Object?>.from(event as Map);
          return _mapToLocationData(raw);
        })
        .handleError((Object error) {
          if (error is PlatformException) {
            // Re-throw as a typed Dart error so callers don't see raw strings
            throw locationErrorFromCode(error.code, error.message);
          }
          throw error; // unknown — rethrow as-is
        });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Converts a raw channel map into a [LocationData] value object.
  ///
  /// Exposed as a static method so it can be used in unit tests without
  /// spinning up a real channel.
  static LocationData mapToLocationData(Map<Object?, Object?> raw) =>
      _mapToLocationData(raw);

  static LocationData _mapToLocationData(Map<Object?, Object?> raw) {
    // Guard against unexpected null values from the native side
    final lat = (raw['lat'] as num?)?.toDouble();
    final lng = (raw['lng'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      throw const LocationUnavailable('Received null coordinates from native');
    }

    return LocationData(
      latitude: lat,
      longitude: lng,
      accuracy: (raw['accuracy'] as num?)?.toDouble(),
      speed: (raw['speed'] as num?)?.toDouble(),
      bearing: (raw['bearing'] as num?)?.toDouble(),
      timestamp: raw['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(raw['timestamp'] as int)
          : DateTime.now(),
    );
  }

  /// Converts a [PlatformException] to a typed location error and throws it.
  static Never _throwMapped(PlatformException e) {
    throw locationErrorFromCode(e.code, e.message);
  }
}

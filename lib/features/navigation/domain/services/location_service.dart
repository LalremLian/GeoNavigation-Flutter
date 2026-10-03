import '../../data/services/location_channel_service.dart';
import '../entities/location_data.dart';

/// Public domain-level API for all location operations.
///
/// This is the ONLY location-related class that [NavigationController]
/// and the rest of the app interact with. It wraps [LocationChannelService]
/// and exposes a clean, typed interface.
///
/// No MethodChannel or EventChannel references escape beyond this class.
class LocationService {
  LocationService({LocationChannelService? channelService})
      : _channel = channelService ?? LocationChannelService();

  final LocationChannelService _channel;

  // ---------------------------------------------------------------------------
  // Permission & service checks
  // ---------------------------------------------------------------------------

  /// Requests the location permission from the OS.
  ///
  /// Throws [LocationPermissionDenied] or [LocationPermissionPermanentlyDenied].
  Future<void> requestPermission() => _channel.requestPermission();

  /// Returns true if fine location permission is currently granted.
  Future<bool> hasPermission() => _channel.hasPermission();

  /// Returns true if GPS / network location is switched on.
  Future<bool> isLocationServiceEnabled() =>
      _channel.isLocationServiceEnabled();

  // ---------------------------------------------------------------------------
  // Location fixes
  // ---------------------------------------------------------------------------

  /// Returns the current device location, requesting a fresh fix if needed.
  ///
  /// Throws a typed [AppError] on any failure (see location_errors.dart).
  Future<LocationData> getCurrentLocation() => _channel.getCurrentLocation();

  // ---------------------------------------------------------------------------
  // Continuous updates
  // ---------------------------------------------------------------------------

  /// Broadcast stream of location updates.
  ///
  /// Native location callbacks start when the first subscriber listens
  /// and stop when the subscription is cancelled. Always cancel the
  /// subscription in the owning controller's [onClose].
  Stream<LocationData> locationStream() => _channel.locationStream();

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// Opens the system app-settings page so the user can grant
  /// permanently-denied permissions.
  Future<void> openAppSettings() => _channel.openAppSettings();

  /// Opens the system Location settings screen so the user can enable GPS.
  Future<void> openLocationSettings() => _channel.openLocationSettings();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Called from [NavigationController.onClose] — no-op for now;
  /// the EventChannel stream is cleaned up by cancelling its subscription.
  void dispose() {}
}

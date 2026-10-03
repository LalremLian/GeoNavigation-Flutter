import '../../data/services/location_channel_service.dart';
import '../entities/location_data.dart';

class LocationService {
  LocationService({LocationChannelService? channelService})
      : _channel = channelService ?? LocationChannelService();

  final LocationChannelService _channel;

  /// Requests the location permission from the OS.
  Future<void> requestPermission() => _channel.requestPermission();

  /// Returns true if fine location permission is currently granted.
  Future<bool> hasPermission() => _channel.hasPermission();

  /// Returns true if GPS / network location is switched on.
  Future<bool> isLocationServiceEnabled() => _channel.isLocationServiceEnabled();

  /// Returns the current device location.
  Future<LocationData> getCurrentLocation() => _channel.getCurrentLocation();

  /// Broadcast stream of location updates.
  Stream<LocationData> locationStream() => _channel.locationStream();

  /// Opens the system app-settings page so the user can grant permanently-denied permissions.
  Future<void> openAppSettings() => _channel.openAppSettings();

  /// Opens the system Location settings screen so the user can enable GPS.
  Future<void> openLocationSettings() => _channel.openLocationSettings();

  /// Called from [NavigationController.onClose] — no-op for now;
  void dispose() {}
}

/// Channel name constants shared between Dart and Kotlin.
///
/// These strings MUST match exactly what is registered in MainActivity.kt.
/// Centralised here so a typo in one place doesn't cause a silent channel mismatch.
abstract final class ChannelConstants {
  /// One-shot commands: requestPermission, getCurrentLocation, openAppSettings, etc.
  static const String locationMethod = 'com.example.navtest/location';

  /// Continuous location stream via EventChannel.
  static const String locationStream = 'com.example.navtest/location_stream';

  /// MethodChannel key used to fetch flavor config at startup.
  static const String appConfig = 'com.example.navtest/app_config';
}

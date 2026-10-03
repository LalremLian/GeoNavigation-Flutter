import 'package:flutter/services.dart';

import '../constants/channel_constants.dart';

/// Immutable application configuration resolved at startup from the native
/// Android [BuildConfig] fields injected per flavor.
///
/// The rest of the app reads from [AppConfig.instance] — no class in business
/// logic or UI ever calls a [MethodChannel] directly for config values.
class AppConfig {
  const AppConfig._({
    required this.routingBaseUrl,
    required this.flavorName,
  });

  /// The OSRM (or compatible) routing server base URL.
  /// Injected via buildConfigField in build.gradle.kts per flavor.
  final String routingBaseUrl;

  /// The current build flavor: "dev" or "prod".
  final String flavorName;

  /// Whether this is a development build.
  bool get isDev => flavorName == 'dev';

  // ---------------------------------------------------------------------------
  // Singleton — initialised once at app startup via [initialise].
  // ---------------------------------------------------------------------------

  static AppConfig? _instance;

  /// The resolved config. Throws if [initialise] has not been called yet.
  static AppConfig get instance {
    assert(
      _instance != null,
      'AppConfig.initialise() must be called before accessing AppConfig.instance',
    );
    return _instance!;
  }

  /// Fetches config from the native side via [MethodChannel] and stores it.
  ///
  /// Called once in [main] before [runApp]. Safe to call multiple times —
  /// subsequent calls are no-ops once initialised.
  static Future<void> initialise() async {
    if (_instance != null) return;

    const channel = MethodChannel(ChannelConstants.appConfig);
    try {
      final result = await channel.invokeMapMethod<String, dynamic>('getConfig');
      _instance = AppConfig._(
        routingBaseUrl: result?['routingBaseUrl'] as String? ??
            'https://router.project-osrm.org',
        flavorName: result?['flavorName'] as String? ?? 'prod',
      );
    } on MissingPluginException {
      // Channel not yet wired (e.g. unit tests or early dev phase).
      // Fall back to safe defaults so the app can still run.
      _instance = const AppConfig._(
        routingBaseUrl: 'https://router.project-osrm.org',
        flavorName: 'prod',
      );
    } on PlatformException catch (e) {
      // Native side threw — use defaults and log for debugging.
      // ignore: avoid_print
      print('[AppConfig] Failed to load native config: ${e.message}. Using defaults.');
      _instance = const AppConfig._(
        routingBaseUrl: 'https://router.project-osrm.org',
        flavorName: 'prod',
      );
    }
  }

  /// Override used in tests to inject a specific config without a channel.
  // ignore: use_setters_to_change_properties
  static void overrideForTesting(AppConfig config) {
    _instance = config;
  }

  /// Resets the singleton — test teardown only.
  static void resetForTesting() {
    _instance = null;
  }

  @override
  String toString() =>
      'AppConfig(flavor: $flavorName, routingBaseUrl: $routingBaseUrl)';
}

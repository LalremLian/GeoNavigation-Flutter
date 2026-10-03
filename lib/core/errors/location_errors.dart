import 'app_error.dart';

/// The user denied the location permission request.
final class LocationPermissionDenied extends AppError {
  const LocationPermissionDenied()
      : super('Location permission was denied by the user.');
}

/// The user denied the permission and selected "Don\'t ask again".
/// The app must direct the user to system settings to re-enable.
final class LocationPermissionPermanentlyDenied extends AppError {
  const LocationPermissionPermanentlyDenied()
      : super(
          'Location permission is permanently denied. '
          'Please enable it in app settings.',
        );
}

/// The device GPS / network location provider is switched off.
final class LocationServicesDisabled extends AppError {
  const LocationServicesDisabled()
      : super('Location services (GPS) are disabled on this device.');
}

/// A fresh location fix was requested but no fix arrived within the timeout.
final class LocationTimeout extends AppError {
  const LocationTimeout()
      : super('Timed out waiting for a location fix.');
}

/// The device does not support location (e.g. no Google Play Services,
/// or running on an unsupported platform such as desktop/web).
final class LocationNotSupported extends AppError {
  const LocationNotSupported()
      : super('Location is not supported on this platform or device.');
}

/// A location was requested but the provider returned nothing useful
/// (e.g. no cached fix and GPS is taking too long).
final class LocationUnavailable extends AppError {
  const LocationUnavailable([String detail = ''])
      : super('Location is temporarily unavailable. $detail');
}

/// Maps the raw Kotlin error code string to the correct typed [AppError].
///
/// Called only inside [LocationChannelService] — the rest of the app
/// never sees raw strings from the channel.
AppError locationErrorFromCode(String code, [String? message]) {
  return switch (code) {
    'PERMISSION_DENIED' => const LocationPermissionDenied(),
    'PERMISSION_PERMANENTLY_DENIED' =>
      const LocationPermissionPermanentlyDenied(),
    'LOCATION_SERVICE_DISABLED' => const LocationServicesDisabled(),
    'LOCATION_TIMEOUT' => const LocationTimeout(),
    'NOT_SUPPORTED' => const LocationNotSupported(),
    _ => LocationUnavailable(message ?? code),
  };
}

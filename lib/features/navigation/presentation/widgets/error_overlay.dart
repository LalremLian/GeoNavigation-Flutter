import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/location_errors.dart';
import '../../../../core/errors/routing_errors.dart';
import '../controllers/navigation_controller.dart';

/// Displays a contextual error card when the controller has a non-null error.
///
/// Covers location permission errors, routing errors, etc.
/// Dismissed automatically when the error is cleared.
class ErrorOverlay extends StatelessWidget {
  const ErrorOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return Obx(() {
      final err = controller.error.value;
      if (err == null) return const SizedBox.shrink();

      final (icon, title, message, action) = _describe(err, controller);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: Colors.red.shade700, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900)),
                        const SizedBox(height: 2),
                        Text(message,
                            style: const TextStyle(fontSize: 12)),
                        if (action != null) ...[
                          const SizedBox(height: 8),
                          action,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Maps an [AppError] to human-readable UI strings and an optional action widget.
  (IconData, String, String, Widget?) _describe(
    dynamic err,
    NavigationController controller,
  ) {
    return switch (err) {
      LocationPermissionDenied() => (
          Icons.location_off,
          'Location permission denied',
          'Grant location permission to use navigation.',
          TextButton(
            onPressed: controller.recenter, // TODO: retrigger permission
            child: const Text('Grant permission'),
          ),
        ),
      LocationPermissionPermanentlyDenied() => (
          Icons.block,
          'Permission permanently denied',
          'Open Settings and enable location for NavTest.',
          TextButton(
            onPressed: null, // TODO: openAppSettings
            child: const Text('Open Settings'),
          ),
        ),
      LocationServicesDisabled() => (
          Icons.gps_off,
          'GPS is off',
          'Enable location services in device settings.',
          null,
        ),
      LocationTimeout() => (
          Icons.timer_off,
          'Location timeout',
          'Could not get a GPS fix. Move to an open area.',
          null,
        ),
      LocationNotSupported() => (
          Icons.warning,
          'Location not supported',
          'This device or platform does not support location.',
          null,
        ),
      LocationUnavailable() => (
          Icons.location_searching,
          'Location unavailable',
          err.message,
          null,
        ),
      NoRouteFound() => (
          Icons.alt_route,
          'No route found',
          'Could not find a driving route to the selected point.',
          null,
        ),
      RoutingNetworkError() => (
          Icons.wifi_off,
          'Network error',
          'Check your internet connection and long-press to try again.',
          null,
        ),
      RoutingTimeout() => (
          Icons.timer_off,
          'Request timed out',
          'The routing server took too long. Try again.',
          null,
        ),
      _ => (
          Icons.error_outline,
          'Error',
          err.message,
          null,
        ),
    };
  }
}

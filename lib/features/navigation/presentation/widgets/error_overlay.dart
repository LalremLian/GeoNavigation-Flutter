import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/location_errors.dart';
import '../../../../core/errors/routing_errors.dart';
import '../controllers/navigation_controller.dart';

/// Displays a contextual error card overlaid on the map when the controller
/// has a non-null [NavigationController.error].
///
/// Auto-dismisses when the error is cleared. Each error type shows a
/// tailored message and optional action button.
class ErrorOverlay extends StatelessWidget {
  const ErrorOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return Obx(() {
      final err = controller.error.value;
      if (err == null) return const SizedBox.shrink();

      final content = _buildContent(err, controller);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(content.icon, color: Colors.red.shade700, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          content.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          content.message,
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (content.actionLabel != null) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 30,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: content.onAction,
                              child: Text(
                                content.actionLabel!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Dismiss button
                  GestureDetector(
                    onTap: () => controller.error.value = null,
                    child: Icon(Icons.close,
                        size: 18, color: Colors.red.shade400),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  _ErrorContent _buildContent(
      AppError err, NavigationController controller) {
    return switch (err) {
      LocationPermissionDenied() => _ErrorContent(
          icon: Icons.location_off,
          title: 'Location permission denied',
          message: 'Tap to grant location access and show your position.',
          actionLabel: 'Grant permission',
          onAction: controller.retryLocation,
        ),
      LocationPermissionPermanentlyDenied() => _ErrorContent(
          icon: Icons.block,
          title: 'Permission permanently denied',
          message: 'Open Settings and enable location for NavTest.',
          actionLabel: 'Open Settings',
          onAction: controller.openAppSettings,
        ),
      LocationServicesDisabled() => _ErrorContent(
          icon: Icons.gps_off,
          title: 'GPS is disabled',
          message: 'Enable location services in device settings to continue navigation.',
          actionLabel: 'Turn on GPS',
          onAction: controller.openLocationSettings,
        ),
      LocationTimeout() => _ErrorContent(
          icon: Icons.timer_off,
          title: 'Location timeout',
          message: 'No GPS fix. Move to open sky and retry.',
          actionLabel: 'Retry',
          onAction: controller.retryLocation,
        ),
      LocationNotSupported() => _ErrorContent(
          icon: Icons.warning_amber,
          title: 'Location not supported',
          message: 'This device or platform does not support location.',
        ),
      LocationUnavailable() => _ErrorContent(
          icon: Icons.location_searching,
          title: 'Location unavailable',
          message: err.message,
          actionLabel: 'Retry',
          onAction: controller.retryLocation,
        ),
      NoRouteFound() => _ErrorContent(
          icon: Icons.alt_route,
          title: 'No route found',
          message: 'Could not find a driving route. Try a different destination.',
        ),
      RoutingNetworkError() => _ErrorContent(
          icon: Icons.wifi_off,
          title: 'Network error',
          message: 'Check your internet connection and long-press to try again.',
        ),
      RoutingTimeout() => _ErrorContent(
          icon: Icons.timer_off,
          title: 'Request timed out',
          message: 'The routing server took too long. Try again.',
        ),
      RoutingParseError() => _ErrorContent(
          icon: Icons.error_outline,
          title: 'Route error',
          message: 'Could not read the route from the server.',
        ),
      InvalidRoute() => _ErrorContent(
          icon: Icons.error_outline,
          title: 'Invalid route',
          message: 'The server returned an unusable route.',
        ),
      _ => _ErrorContent(
          icon: Icons.error_outline,
          title: 'Error',
          message: err.message,
        ),
    };
  }
}

/// Simple data class holding content for one error card.
class _ErrorContent {
  const _ErrorContent({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
}

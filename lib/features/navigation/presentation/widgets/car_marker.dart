import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../domain/entities/navigation_state.dart';
import '../controllers/navigation_controller.dart';

/// Renders the animated car icon on the map.
///
/// Reads [NavigationController.engineState] and rotates/positions the icon
/// according to bearing and position. No navigation mathematics lives here —
/// all computation is done in [NavigationEngine].
///
/// The car is shown:
///   - At the route start point once a route is ready (before Start is pressed)
///   - While navigating, paused, or completed
class CarMarker extends StatelessWidget {
  const CarMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return Obx(() {
      final state = controller.engineState.value;
      if (state == null) return const SizedBox.shrink();

      // Show car at start point when ready, and during/after navigation
      final status = controller.navStatus.value;
      final showCar = status == NavigationStatus.ready ||
          status == NavigationStatus.navigating ||
          status == NavigationStatus.paused ||
          status == NavigationStatus.completed;
      if (!showCar) return const SizedBox.shrink();

      return MarkerLayer(
        markers: [
          Marker(
            point: state.position,
            width: 48,
            height: 48,
            child: _CarIcon(bearingDegrees: controller.visualBearingDegrees.value),
          ),
        ],
      );
    });
  }
}

/// Car pointer using the top-down [car_icon.png] asset.
///
/// Rotated by [bearingDegrees] so it points in the direction of travel.
/// [Transform.rotate] uses radians, clockwise positive, matching
/// the 0°=north / 90°=east bearing convention.
class _CarIcon extends StatelessWidget {
  const _CarIcon({required this.bearingDegrees});

  final double bearingDegrees;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: bearingDegrees * math.pi / 180,
      child: Image.asset(
        'assets/icons/car_icon.png',
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

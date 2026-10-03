import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../domain/entities/navigation_state.dart';
import '../controllers/navigation_controller.dart';

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

/// Car pointer
/// Rotated by [bearingDegrees] so it points in the direction of travel.
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

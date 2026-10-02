import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../domain/entities/navigation_state.dart';
import '../controllers/navigation_controller.dart';

/// Renders the animated car icon on the map.
///
/// Reads [NavigationController.engineState] and rotates/positions the icon
/// according to bearing and position. No navigation math lives here.
class CarMarker extends StatelessWidget {
  const CarMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return Obx(() {
      final state = controller.engineState.value;
      if (state == null) return const SizedBox.shrink();

      // Don't show the car until navigation has started
      final status = controller.navStatus.value;
      final showCar = status == NavigationStatus.navigating ||
          status == NavigationStatus.paused ||
          status == NavigationStatus.completed;
      if (!showCar) return const SizedBox.shrink();

      return MarkerLayer(
        markers: [
          Marker(
            point: state.position,
            width: 36,
            height: 36,
            child: Transform.rotate(
              angle: state.bearingDegrees * math.pi / 180,
              child: const Icon(
                Icons.navigation,
                color: Colors.deepOrange,
                size: 36,
              ),
            ),
          ),
        ],
      );
    });
  }
}

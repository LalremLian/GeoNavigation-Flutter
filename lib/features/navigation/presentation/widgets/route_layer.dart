import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../controllers/navigation_controller.dart';

/// Draws the decoded route polyline on the map.
///
/// Stateless — re-renders whenever [NavigationController.route] changes.
class RouteLayer extends StatelessWidget {
  const RouteLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return Obx(() {
      final r = controller.route.value;
      if (r == null || r.isEmpty) return const SizedBox.shrink();

      final covered = controller.engineState.value?.coveredPoints ?? const [];

      return PolylineLayer(
        polylines: [
          // 1. Full/uncovered route (vibrant navigation blue)
          Polyline(
            points: r.points,
            strokeWidth: 6,
            color: Colors.blue.shade600,
            strokeCap: StrokeCap.round,
            strokeJoin: StrokeJoin.round,
          ),

          // 2. Covered/traveled route segment (light grey so user can see progress)
          if (covered.length >= 2)
            Polyline(
              points: covered,
              strokeWidth: 6,
              color: Colors.grey.shade400.withValues(alpha: 0.9),
              strokeCap: StrokeCap.round,
              strokeJoin: StrokeJoin.round,
            ),
        ],
      );
    });
  }
}

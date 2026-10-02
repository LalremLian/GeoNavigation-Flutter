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

      return PolylineLayer(
        polylines: [
          Polyline(
            points: r.points,
            strokeWidth: 5,
            color: Colors.blue.shade700,
          ),
        ],
      );
    });
  }
}

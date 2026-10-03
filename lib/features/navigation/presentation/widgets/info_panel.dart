import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/distance_utils.dart';
import '../../domain/entities/navigation_state.dart';
import '../controllers/navigation_controller.dart';

/// Overlay panel showing total and remaining distance/duration.
///
/// Sits at the top of the screen over the map.
class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return Obx(() {
      final r = controller.route.value;
      if (r == null) return const SizedBox.shrink();

      final state = controller.engineState.value;
      final isNavigating = controller.navStatus.value == NavigationStatus.navigating ||
          controller.navStatus.value == NavigationStatus.paused;

      return SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Total route info
              _InfoItem(
                label: 'Total',
                distance: DistanceUtils.format(r.totalDistanceMeters),
                duration: DistanceUtils.formatDuration(r.totalDurationSeconds),
              ),
              if (isNavigating && state != null) ...[
                const SizedBox(width: 20),
                const VerticalDivider(thickness: 1, width: 1),
                const SizedBox(width: 20),
                // Remaining info
                _InfoItem(
                  label: 'Remaining',
                  distance: DistanceUtils.format(state.remainingDistanceMeters),
                  duration: DistanceUtils.formatDuration(
                    state.remainingDurationSeconds,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.distance,
    required this.duration,
  });

  final String label;
  final String distance;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(distance,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold)),
        Text(duration,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

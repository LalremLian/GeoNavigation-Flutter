import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/navigation_state.dart';
import '../controllers/navigation_controller.dart';
import 'speed_selector.dart';

/// Bottom control bar with Start / Pause / Resume / Reset and speed selector.
class ControlBar extends StatelessWidget {
  const ControlBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Obx(() {
          final status = controller.navStatus.value;
          final hasRoute = controller.route.value != null;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Start button
                  if (status == NavigationStatus.ready)
                    _NavButton(
                      label: 'Start',
                      icon: Icons.play_arrow,
                      color: Colors.green,
                      onTap: controller.start,
                    ),

                  // Pause button
                  if (status == NavigationStatus.navigating)
                    _NavButton(
                      label: 'Pause',
                      icon: Icons.pause,
                      color: Colors.orange,
                      onTap: controller.pause,
                    ),

                  // Resume button
                  if (status == NavigationStatus.paused)
                    _NavButton(
                      label: 'Resume',
                      icon: Icons.play_arrow,
                      color: Colors.green,
                      onTap: controller.resume,
                    ),

                  // Reset button — visible whenever a route is loaded
                  if (hasRoute &&
                      status != NavigationStatus.idle &&
                      status != NavigationStatus.loadingLocation &&
                      status != NavigationStatus.loadingRoute)
                    _NavButton(
                      label: 'Reset',
                      icon: Icons.replay,
                      color: Colors.grey.shade700,
                      onTap: controller.reset,
                    ),
                ],
              ),
              if (hasRoute) ...[
                const SizedBox(height: 8),
                const SpeedSelector(),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

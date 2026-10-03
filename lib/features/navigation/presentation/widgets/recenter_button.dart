import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/navigation_state.dart';
import '../controllers/navigation_controller.dart';

class RecenterButton extends StatelessWidget {
  const RecenterButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return Obx(() {
      final following = controller.cameraFollowing.value;
      final status = controller.navStatus.value;

      /// Only show when car is on screen and user has panned away
      final isNavigating = status == NavigationStatus.navigating ||
          status == NavigationStatus.paused;

      if (following || !isNavigating) return const SizedBox.shrink();

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 148),
          child: FloatingActionButton.small(
            heroTag: 'recenter_btn',
            onPressed: controller.recenter,
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue.shade700,
            elevation: 4,
            tooltip: 'Re-centre on vehicle',
            child: const Icon(Icons.my_location, size: 20),
          ),
        ),
      );
    });
  }
}

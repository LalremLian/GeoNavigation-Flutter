import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navigation_controller.dart';

/// Floating recenter button — only visible after the user manually pans.
class RecenterButton extends StatelessWidget {
  const RecenterButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return Obx(() {
      if (controller.cameraFollowing.value) return const SizedBox.shrink();

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 100),
          child: FloatingActionButton.small(
            onPressed: controller.recenter,
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue.shade700,
            tooltip: 'Re-center on vehicle',
            child: const Icon(Icons.my_location),
          ),
        ),
      );
    });
  }
}

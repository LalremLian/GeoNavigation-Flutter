import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navigation_controller.dart';

class SpeedSelector extends StatelessWidget {
  const SpeedSelector({super.key});

  static const List<int> _speeds = [1, 2, 5];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return Obx(() {
      final current = controller.speedMultiplier.value;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _speeds.map((speed) {
          final isSelected = current == speed;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text('${speed}x'),
              selected: isSelected,
              onSelected: (_) => controller.setSpeed(speed),
              selectedColor: Colors.blue.shade700,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

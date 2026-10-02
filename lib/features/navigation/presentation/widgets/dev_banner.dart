import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';

/// Renders a visible "DEV" badge in the top-right corner.
///
/// Renders nothing in the prod flavor — zero cost at runtime.
class DevBanner extends StatelessWidget {
  const DevBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.instance.isDev) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: const BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
            ),
          ),
          child: const Text(
            'DEV',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

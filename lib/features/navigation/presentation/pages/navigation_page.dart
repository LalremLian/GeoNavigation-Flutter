import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/navigation_state.dart';
import '../controllers/navigation_controller.dart';
import '../widgets/arrival_dialog.dart';
import '../widgets/control_bar.dart';
import '../widgets/dev_banner.dart';
import '../widgets/error_overlay.dart';
import '../widgets/info_panel.dart';
import '../widgets/map_view.dart';
import '../widgets/permission_prompt_card.dart';
import '../widgets/recenter_button.dart';

/// The single application screen.
///
/// Hosts the map, overlaid controls, error states and loading indicator.
/// All business logic is delegated to [NavigationController].
class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage>
    with TickerProviderStateMixin {
  late final NavigationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<NavigationController>();
    // Provide the TickerProvider so the controller can drive car animation
    _controller.initTicker(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // -------------------------------------------------------------------
          // Full-screen map (always rendered behind everything)
          // -------------------------------------------------------------------
          const MapView(),

          // -------------------------------------------------------------------
          // DEV flavor badge — renders nothing in prod
          // -------------------------------------------------------------------
          const DevBanner(),

          // -------------------------------------------------------------------
          // Contextual Permission Prompt Card (shown when permission needed)
          // -------------------------------------------------------------------
          const Align(
            alignment: Alignment.topCenter,
            child: PermissionPromptCard(),
          ),

          // -------------------------------------------------------------------
          // Error overlay — shown when controller.error != null
          // -------------------------------------------------------------------
          const Align(
            alignment: Alignment.topCenter,
            child: ErrorOverlay(),
          ),

          // -------------------------------------------------------------------
          // Distance / duration info panel
          // -------------------------------------------------------------------
          const Positioned(
            left: 0,
            bottom: 145,
            child: InfoPanel(),
          ),

          // -------------------------------------------------------------------
          // Location loading indicator
          // -------------------------------------------------------------------
          Obx(() {
            final loading = _controller.navStatus.value ==
                NavigationStatus.loadingLocation;
            if (!loading) return const SizedBox.shrink();
            return const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _LoadingChip(label: 'Getting location…'),
              ),
            );
          }),

          // -------------------------------------------------------------------
          // Route loading indicator
          // -------------------------------------------------------------------
          Obx(() {
            final loading = _controller.navStatus.value ==
                NavigationStatus.loadingRoute;
            if (!loading) return const SizedBox.shrink();
            return const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _LoadingChip(label: 'Finding route…'),
              ),
            );
          }),

          // -------------------------------------------------------------------
          // Start / Pause / Resume / Reset + speed controls
          // -------------------------------------------------------------------
          Obx(() {
            if (_controller.route.value == null) {
              return const SizedBox.shrink();
            }

            return const Align(
              alignment: Alignment.bottomCenter,
              child: ControlBar(),
            );
          }),

          // -------------------------------------------------------------------
          // Recenter button — visible only after manual map pan
          // -------------------------------------------------------------------
          const Align(
            alignment: Alignment.bottomRight,
            child: RecenterButton(),
          ),

          // -------------------------------------------------------------------
          // Arrival Dialog — shown when car reaches destination
          // -------------------------------------------------------------------
          const ArrivalDialog(),
        ],
      ),
    );
  }
}

/// Small pill-shaped loading indicator shown over the map.
class _LoadingChip extends StatelessWidget {
  const _LoadingChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

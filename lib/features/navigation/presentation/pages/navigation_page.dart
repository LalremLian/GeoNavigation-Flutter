import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navigation_controller.dart';
import '../widgets/control_bar.dart';
import '../widgets/dev_banner.dart';
import '../widgets/info_panel.dart';
import '../widgets/map_view.dart';
import '../widgets/recenter_button.dart';

/// The single application screen.
///
/// Hosts the map, overlaid controls, and error states.
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
    // Provide the TickerProvider so the controller can drive animation
    _controller.initTicker(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          const MapView(),

          // DEV flavor badge — renders nothing in prod
          const DevBanner(),

          // Distance / duration info panel
          const Align(
            alignment: Alignment.topCenter,
            child: InfoPanel(),
          ),

          // Start / Pause / Resume / Reset + speed controls
          const Align(
            alignment: Alignment.bottomCenter,
            child: ControlBar(),
          ),

          // Recenter button — visible only after manual map pan
          const Align(
            alignment: Alignment.bottomRight,
            child: RecenterButton(),
          ),
        ],
      ),
    );
  }
}

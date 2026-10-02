import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'core/config/app_config.dart';
import 'features/navigation/presentation/controllers/navigation_binding.dart';
import 'features/navigation/presentation/pages/navigation_page.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialised before any platform channel calls.
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for a consistent navigation experience.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Resolve flavor-injected config (routing URL, flavor name) from native side.
  // Falls back to safe defaults if the channel isn't wired yet (e.g. Phase 1).
  await AppConfig.initialise();

  runApp(const GeoNavigationApp());
}

class GeoNavigationApp extends StatelessWidget {
  const GeoNavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'NavTest',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),

      // GetX named routes — single-screen app, so only one route needed.
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => const NavigationPage(),
          binding: NavigationBinding(),
        ),
      ],
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      // Ensure map overlays have a clean background
      scaffoldBackgroundColor: Colors.white,
    );
  }
}

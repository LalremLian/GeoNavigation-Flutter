import 'package:get/get.dart';

import '../../../../core/config/app_config.dart';
import '../../data/repositories/routing_repository.dart';
import '../../data/services/osrm_service.dart';
import '../../domain/services/location_service.dart';
import 'navigation_controller.dart';

class NavigationBinding extends Bindings {
  @override
  void dependencies() {
    /// OsrmService: reads the routing URL from flavor config
    Get.lazyPut<OsrmService>(
      () => OsrmService(baseUrl: AppConfig.instance.routingBaseUrl),
    );

    /// RoutingRepository: depends on OsrmService
    Get.lazyPut<RoutingRepository>(
      () => RoutingRepository(osrmService: Get.find()),
    );

    /// LocationService: wraps the native channel bridge
    Get.lazyPut<LocationService>(() => LocationService());

    /// NavigationController: the central coordinator
    Get.lazyPut<NavigationController>(
      () => NavigationController(
        locationService: Get.find(),
        routingRepository: Get.find(),
      ),
    );
  }
}

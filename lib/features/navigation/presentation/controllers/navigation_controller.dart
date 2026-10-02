import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/errors/app_error.dart';
import '../../data/models/route_model.dart';
import '../../data/repositories/routing_repository.dart';
import '../../domain/entities/engine_state.dart';
import '../../domain/entities/location_data.dart';
import '../../domain/entities/navigation_state.dart';
import '../../domain/services/location_service.dart';
import '../../domain/services/navigation_engine.dart';

/// Central GetX controller — coordinates all domain services and exposes
/// observable state to the UI.
///
/// Business logic lives in [LocationService], [RoutingRepository] and
/// [NavigationEngine]. This controller wires them together and drives the
/// animation ticker.
class NavigationController extends GetxController with WidgetsBindingObserver {
  NavigationController({
    required LocationService locationService,
    required RoutingRepository routingRepository,
  })  : _locationService = locationService,
        _routingRepository = routingRepository,
        _engine = NavigationEngine();

  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final LocationService _locationService;
  final RoutingRepository _routingRepository;
  // ignore: unused_field — used in Phase 8
  final NavigationEngine _engine;

  // ---------------------------------------------------------------------------
  // Animation ticker
  // ---------------------------------------------------------------------------

  // Ticker for driving animation — initialised via initTicker(), started in Phase 7
  // ignore: unused_field
  Ticker? _ticker;
  // ignore: prefer_final_fields, unused_field — mutated in Phase 7
  Duration _lastTickTime = Duration.zero;

  // ---------------------------------------------------------------------------
  // Observable state
  // ---------------------------------------------------------------------------

  final Rx<LocationData?> currentLocation = Rx(null);
  final Rx<LatLng?> destination = Rx(null);
  final Rx<RouteModel?> route = Rx(null);
  final Rx<EngineState?> engineState = Rx(null);
  final Rx<NavigationStatus> navStatus = NavigationStatus.idle.obs;
  final RxBool isLoadingRoute = false.obs;
  final Rx<AppError?> error = Rx(null);
  final RxInt speedMultiplier = 1.obs;
  final RxBool cameraFollowing = true.obs;

  // ---------------------------------------------------------------------------
  // Stale-request protection
  // ---------------------------------------------------------------------------

  // ignore: prefer_final_fields, unused_field — mutated in Phase 5
  int _routeRequestVersion = 0;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initLocation();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    _ticker = null;
    _locationService.dispose();
    _routingRepository.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO(phase10): implement background/foreground transitions
  }

  // ---------------------------------------------------------------------------
  // Location initialisation
  // ---------------------------------------------------------------------------

  Future<void> _initLocation() async {
    // TODO(phase3): implement
  }

  // ---------------------------------------------------------------------------
  // Destination & routing
  // ---------------------------------------------------------------------------

  void onMapLongPress(LatLng tappedPoint) {
    // TODO(phase4): implement
  }

  // ignore: unused_element — implemented in Phase 5
  Future<void> _fetchRoute(LatLng dest) async {
    // TODO(phase5): implement
  }

  // ---------------------------------------------------------------------------
  // Navigation controls
  // ---------------------------------------------------------------------------

  void start() {
    // TODO(phase8): implement
  }

  void pause() {
    // TODO(phase8): implement
  }

  void resume() {
    // TODO(phase8): implement
  }

  void reset() {
    // TODO(phase8): implement
  }

  void setSpeed(int multiplier) {
    // TODO(phase8): implement
  }

  // ---------------------------------------------------------------------------
  // Camera
  // ---------------------------------------------------------------------------

  void onUserMapGesture() {
    // TODO(phase9): implement
  }

  void recenter() {
    // TODO(phase9): implement
  }

  // ---------------------------------------------------------------------------
  // Ticker / animation
  // ---------------------------------------------------------------------------

  // ignore: unused_element — implemented in Phase 7
  void _startTicker(TickerProvider vsync) {
    // TODO(phase7): implement
  }

  // ignore: unused_element — wired in Phase 7
  void _stopTicker() {
    _ticker?.stop();
  }

  void _onTick(Duration elapsed) {
    // TODO(phase7): implement
  }

  // ---------------------------------------------------------------------------
  // Ticker provider injection
  // ---------------------------------------------------------------------------

  /// Called once from [NavigationPage] after the widget tree is mounted,
  /// so the controller can create a [Ticker] backed by the page's vsync.
  void initTicker(TickerProvider vsync) {
    if (_ticker != null) return; // guard against double-init
    _ticker = vsync.createTicker(_onTick);
  }
}

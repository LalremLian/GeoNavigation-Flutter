import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/location_errors.dart';
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
  // Location stream
  // ---------------------------------------------------------------------------

  StreamSubscription<LocationData>? _locationSubscription;

  // ---------------------------------------------------------------------------
  // Map controller (injected from MapView in Phase 3)
  // ---------------------------------------------------------------------------

  MapController? _mapController;
  bool _hasCenteredOnLocation = false;

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
    _locationSubscription?.cancel();
    _locationSubscription = null;
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
  // Map controller injection
  // ---------------------------------------------------------------------------

  /// Called once from [MapView.initState] so the controller can move
  /// the camera programmatically.
  void attachMapController(MapController mapController) {
    _mapController = mapController;
  }

  // ---------------------------------------------------------------------------
  // Location initialisation
  // ---------------------------------------------------------------------------

  Future<void> _initLocation() async {
    if (isClosed) return;
    navStatus.value = NavigationStatus.loadingLocation;
    error.value = null;

    try {
      // 1. Request permission — throws typed error if denied
      await _locationService.requestPermission();

      // 2. Check GPS is on
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!isClosed) {
          error.value = const LocationServicesDisabled();
          navStatus.value = NavigationStatus.idle;
        }
        return;
      }

      // 3. Get the first fix to centre the map
      final firstFix = await _locationService.getCurrentLocation();
      if (isClosed) return;

      currentLocation.value = firstFix;
      navStatus.value = NavigationStatus.idle;

      // Centre map on first fix (only once)
      _centerMapOnLocation(firstFix, zoom: 15);

      // 4. Subscribe to continuous updates
      _startLocationStream();
    } on LocationPermissionDenied {
      if (!isClosed) {
        error.value = const LocationPermissionDenied();
        navStatus.value = NavigationStatus.idle;
      }
    } on LocationPermissionPermanentlyDenied {
      if (!isClosed) {
        error.value = const LocationPermissionPermanentlyDenied();
        navStatus.value = NavigationStatus.idle;
      }
    } on LocationServicesDisabled {
      if (!isClosed) {
        error.value = const LocationServicesDisabled();
        navStatus.value = NavigationStatus.idle;
      }
    } on LocationNotSupported {
      if (!isClosed) {
        error.value = const LocationNotSupported();
        navStatus.value = NavigationStatus.idle;
      }
    } catch (e) {
      if (!isClosed) {
        error.value = LocationUnavailable(e.toString());
        navStatus.value = NavigationStatus.idle;
      }
    }
  }

  void _startLocationStream() {
    // Cancel any existing subscription before creating a new one
    _locationSubscription?.cancel();

    _locationSubscription = _locationService
        .locationStream()
        .listen(
      (fix) {
        if (isClosed) return;
        currentLocation.value = fix;

        // Centre map on first stream fix if we haven't yet
        if (!_hasCenteredOnLocation) {
          _centerMapOnLocation(fix, zoom: 15);
        }
      },
      onError: (Object e) {
        if (isClosed) return;
        if (e is AppError) {
          error.value = e;
        }
        // Don't crash on stream errors — just surface them
      },
      cancelOnError: false, // keep listening even after a transient error
    );
  }

  void _centerMapOnLocation(LocationData fix, {double zoom = 15}) {
    _hasCenteredOnLocation = true;
    _mapController?.move(
      LatLng(fix.latitude, fix.longitude),
      zoom,
    );
  }

  // ---------------------------------------------------------------------------
  // Destination & routing
  // ---------------------------------------------------------------------------

  /// Called when the user long-presses the map.
  ///
  /// Sets the new destination immediately so the pin appears at once,
  /// resets any in-progress navigation, and starts a new route request.
  /// Any previous in-flight route request is invalidated by incrementing
  /// [_routeRequestVersion] — if the response arrives late it is discarded.
  void onMapLongPress(LatLng tappedPoint) {
    if (isClosed) return;

    // Cancel any active navigation so the old route is cleared
    _stopTicker();

    // Update destination state immediately — pin shows right away
    destination.value = tappedPoint;

    // Clear old route + engine state
    route.value = null;
    engineState.value = null;
    navStatus.value = NavigationStatus.idle;
    error.value = null;

    // Guard: need a current location to calculate a route from
    final loc = currentLocation.value;
    if (loc == null) {
      // No location yet — destination pin is set, route will be fetched
      // automatically once location arrives (Phase 5 handles this)
      return;
    }

    _fetchRoute(tappedPoint);
  }

  Future<void> _fetchRoute(LatLng dest) async {
    if (isClosed) return;

    // Increment version — any older in-flight request will see a mismatch
    // and discard its result
    final myVersion = ++_routeRequestVersion;

    isLoadingRoute.value = true;
    navStatus.value = NavigationStatus.loadingRoute;
    error.value = null;

    try {
      final origin = currentLocation.value;
      if (origin == null) {
        isLoadingRoute.value = false;
        navStatus.value = NavigationStatus.idle;
        return;
      }

      final result = await _routingRepository.getRoute(
        origin: LatLng(origin.latitude, origin.longitude),
        destination: dest,
      );

      // Stale-request guard — discard if a newer request has started
      if (isClosed || myVersion != _routeRequestVersion) return;

      route.value = result;
      isLoadingRoute.value = false;
      navStatus.value = NavigationStatus.ready;
    } catch (e) {
      if (isClosed || myVersion != _routeRequestVersion) return;

      isLoadingRoute.value = false;
      navStatus.value = NavigationStatus.idle;
      if (e is AppError) {
        error.value = e;
      }
      // Non-AppError exceptions (network, etc.) are silently ignored here;
      // RoutingRepository maps them to typed errors in Phase 5.
    }
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

  // ---------------------------------------------------------------------------
  // Public helpers
  // ---------------------------------------------------------------------------

  /// Opens system app settings so the user can re-enable a
  /// permanently-denied location permission.
  Future<void> openAppSettings() => _locationService.openAppSettings();

  /// Dismisses the current error and retries location initialisation.
  void retryLocation() {
    error.value = null;
    _hasCenteredOnLocation = false;
    _initLocation();
  }
}

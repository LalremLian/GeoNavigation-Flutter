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
  final NavigationEngine _engine;

  // ---------------------------------------------------------------------------
  // Animation ticker
  // ---------------------------------------------------------------------------

  Ticker? _ticker;

  /// Elapsed duration at the last tick — used to compute delta time.
  Duration _lastElapsed = Duration.zero;

  /// Whether the ticker is currently running (separate from navStatus
  /// so we can pause/resume without losing state).
  bool _tickerRunning = false;

  // ---------------------------------------------------------------------------
  // Location stream
  // ---------------------------------------------------------------------------

  StreamSubscription<LocationData>? _locationSubscription;

  // ---------------------------------------------------------------------------
  // Map controller (injected from MapView)
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
    _stopTicker();
    _ticker?.dispose();
    _ticker = null;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationService.dispose();
    _routingRepository.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Pause animation when app goes to background
        if (_tickerRunning) _stopTicker();
        break;
      case AppLifecycleState.resumed:
        // Resume animation if we were navigating before backgrounding
        if (navStatus.value == NavigationStatus.navigating && !_tickerRunning) {
          _startTicker();
        }
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Ticker provider injection
  // ---------------------------------------------------------------------------

  /// Called once from [NavigationPage.initState] after the widget tree mounts.
  void initTicker(TickerProvider vsync) {
    if (_ticker != null) return; // guard against double-init
    _ticker = vsync.createTicker(_onTick);
  }

  // ---------------------------------------------------------------------------
  // Map controller injection
  // ---------------------------------------------------------------------------

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
      await _locationService.requestPermission();

      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!isClosed) {
          error.value = const LocationServicesDisabled();
          navStatus.value = NavigationStatus.idle;
        }
        return;
      }

      final firstFix = await _locationService.getCurrentLocation();
      if (isClosed) return;

      currentLocation.value = firstFix;
      navStatus.value = NavigationStatus.idle;
      _centerMapOnLocation(firstFix, zoom: 15);
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
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.locationStream().listen(
      (fix) {
        if (isClosed) return;
        currentLocation.value = fix;
        if (!_hasCenteredOnLocation) _centerMapOnLocation(fix, zoom: 15);
      },
      onError: (Object e) {
        if (isClosed) return;
        if (e is AppError) error.value = e;
      },
      cancelOnError: false,
    );
  }

  void _centerMapOnLocation(LocationData fix, {double zoom = 15}) {
    _hasCenteredOnLocation = true;
    _mapController?.move(LatLng(fix.latitude, fix.longitude), zoom);
  }

  void _fitRouteBounds(RouteModel r) {
    if (_mapController == null || r.points.isEmpty) return;

    double minLat = r.points.first.latitude;
    double maxLat = r.points.first.latitude;
    double minLng = r.points.first.longitude;
    double maxLng = r.points.first.longitude;

    for (final pt in r.points) {
      if (pt.latitude < minLat) minLat = pt.latitude;
      if (pt.latitude > maxLat) maxLat = pt.latitude;
      if (pt.longitude < minLng) minLng = pt.longitude;
      if (pt.longitude > maxLng) maxLng = pt.longitude;
    }

    _mapController!.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Destination & routing
  // ---------------------------------------------------------------------------

  void onMapLongPress(LatLng tappedPoint) {
    if (isClosed) return;
    _stopTicker();
    destination.value = tappedPoint;
    route.value = null;
    engineState.value = null;
    navStatus.value = NavigationStatus.idle;
    error.value = null;

    if (currentLocation.value == null) return;
    _fetchRoute(tappedPoint);
  }

  Future<void> _fetchRoute(LatLng dest) async {
    if (isClosed) return;
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

      if (isClosed || myVersion != _routeRequestVersion) return;

      // Load route into engine so it's ready to animate
      _engine.loadRoute(result);

      route.value = result;
      isLoadingRoute.value = false;
      navStatus.value = NavigationStatus.ready;
      _fitRouteBounds(result);

      // Show the car at the start position immediately
      engineState.value = _engine.advance(Duration.zero);
    } catch (e) {
      if (isClosed || myVersion != _routeRequestVersion) return;
      isLoadingRoute.value = false;
      navStatus.value = NavigationStatus.idle;
      if (e is AppError) error.value = e;
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation controls (Phase 8 — stubbed here, wired fully below)
  // ---------------------------------------------------------------------------

  void start() {
    if (isClosed) return;
    final status = navStatus.value;
    if (status != NavigationStatus.ready && status != NavigationStatus.paused) {
      return;
    }
    navStatus.value = NavigationStatus.navigating;
    cameraFollowing.value = true;
    _startTicker();
  }

  void pause() {
    if (isClosed) return;
    if (navStatus.value != NavigationStatus.navigating) return;
    navStatus.value = NavigationStatus.paused;
    _stopTicker();
  }

  void resume() {
    if (isClosed) return;
    if (navStatus.value != NavigationStatus.paused) return;
    navStatus.value = NavigationStatus.navigating;
    _startTicker();
  }

  void reset() {
    if (isClosed) return;
    _stopTicker();
    _engine.reset();
    final currentRoute = route.value;
    if (currentRoute != null) {
      engineState.value = _engine.advance(Duration.zero);
      navStatus.value = NavigationStatus.ready;
      cameraFollowing.value = true;
      _fitRouteBounds(currentRoute);
    }
  }

  void setSpeed(int multiplier) {
    if (isClosed) return;
    speedMultiplier.value = multiplier;
    _engine.setSpeedMultiplier(multiplier.toDouble());
  }

  // ---------------------------------------------------------------------------
  // Camera
  // ---------------------------------------------------------------------------

  void onUserMapGesture() {
    if (!cameraFollowing.value) return;
    cameraFollowing.value = false;
  }

  void recenter() {
    if (isClosed) return;
    cameraFollowing.value = true;
    final state = engineState.value;
    if (state != null) {
      _mapController?.move(state.position, 16);
    }
  }

  // ---------------------------------------------------------------------------
  // Ticker implementation
  // ---------------------------------------------------------------------------

  void _startTicker() {
    if (_ticker == null || _tickerRunning) return;
    _lastElapsed = Duration.zero;
    _ticker!.start();
    _tickerRunning = true;
  }

  void _stopTicker() {
    if (!_tickerRunning) return;
    _ticker?.stop();
    _tickerRunning = false;
    _lastElapsed = Duration.zero;
  }

  /// Called on every vsync frame while the ticker is active.
  ///
  /// [elapsed] is the total time since the ticker was last started.
  /// We compute delta = elapsed - lastElapsed to get the per-frame step.
  void _onTick(Duration elapsed) {
    if (isClosed) return;
    if (navStatus.value != NavigationStatus.navigating) {
      _stopTicker();
      return;
    }

    // Compute delta time — guard against the first frame (lastElapsed == 0)
    final delta = _lastElapsed == Duration.zero
        ? Duration.zero
        : elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    // Skip the first zero-delta frame to avoid a position jump
    if (delta == Duration.zero) return;

    final state = _engine.advance(delta);
    engineState.value = state;

    // Follow car with camera
    if (cameraFollowing.value) {
      _mapController?.move(state.position, 16);
    }

    // Check completion
    if (state.isCompleted) {
      navStatus.value = NavigationStatus.completed;
      _stopTicker();
    }
  }

  // ---------------------------------------------------------------------------
  // Public helpers
  // ---------------------------------------------------------------------------

  Future<void> openAppSettings() => _locationService.openAppSettings();

  void retryLocation() {
    error.value = null;
    _hasCenteredOnLocation = false;
    _initLocation();
  }
}

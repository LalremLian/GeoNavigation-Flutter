import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:geo_navigation/core/utils/bearing_utils.dart';
import 'package:geo_navigation/core/utils/distance_utils.dart';
import 'package:geo_navigation/features/navigation/data/models/route_model.dart';
import 'package:geo_navigation/features/navigation/domain/services/navigation_engine.dart';

RouteModel route(List<LatLng> points) => RouteModel(
      points: points,
      totalDistanceMeters: 1000,
      totalDurationSeconds: 100,
    );

void main() {
  final northEast = <LatLng>[
    const LatLng(0, 0),
    const LatLng(0.01, 0.01),
  ];

  test('empty route returns completed state', () {
    final engine = NavigationEngine()..loadRoute(route(const []));
    final state = engine.advance(Duration.zero);
    expect(state.isCompleted, isTrue);
    expect(state.progress, 1);
    expect(state.remainingDistanceMeters, 0);
  });

  test('one-point route completes without movement', () {
    final point = const LatLng(1, 2);
    final state = (NavigationEngine()..loadRoute(route([point])))
        .advance(const Duration(seconds: 10));
    expect(state.position, point);
    expect(state.isCompleted, isTrue);
    expect(state.traveledDistanceMeters, 0);
  });

  test('normal route advances and reaches the end', () {
    final engine = NavigationEngine()..loadRoute(route(northEast));
    final state = engine.advance(const Duration(hours: 1));
    expect(state.isCompleted, isTrue);
    expect(state.progress, 1);
  });

  test('duplicate points are skipped', () {
    final points = [const LatLng(0, 0), const LatLng(0, 0), const LatLng(0, 0.01)];
    final state = (NavigationEngine()..loadRoute(route(points)))
        .advance(const Duration(seconds: 1));
    expect(state.position.latitude.isFinite, isTrue);
    expect(state.position.longitude, greaterThan(0));
  });

  test('very close points are handled', () {
    final engine = NavigationEngine()
      ..loadRoute(route([const LatLng(0, 0), const LatLng(0, 0.000001)]));
    expect(engine.hasRoute, isTrue);
    expect(engine.advance(Duration.zero).position.longitude, 0);
  });

  test('zero-distance route does not divide by zero', () {
    final engine = NavigationEngine()
      ..loadRoute(route([const LatLng(1, 1), const LatLng(1, 1)]));
    final state = engine.advance(const Duration(seconds: 1));
    expect(state.position.latitude, 1);
    expect(state.position.longitude, 1);
    expect(state.progress, 1);
  });

  test('haversine distance is approximately one degree of latitude', () {
    final distance = DistanceUtils.haversine(
      lat1: 0,
      lng1: 0,
      lat2: 1,
      lng2: 0,
    );
    expect(distance, closeTo(111195, 500));
  });

  test('position interpolation is between segment endpoints', () {
    final engine = NavigationEngine()..loadRoute(route(northEast));
    final state = engine.advance(const Duration(seconds: 1));
    expect(state.position.latitude, greaterThan(0));
    expect(state.position.latitude, lessThan(0.01));
    expect(state.position.longitude, greaterThan(0));
  });

  test('2x speed covers twice the distance', () {
    final one = NavigationEngine()..loadRoute(route(northEast));
    final two = NavigationEngine()
      ..loadRoute(route(northEast))
      ..setSpeedMultiplier(2);
    final duration = const Duration(seconds: 2);
    expect(two.advance(duration).traveledDistanceMeters,
        closeTo(one.advance(duration).traveledDistanceMeters * 2, 0.001));
  });

  test('1x speed uses the base speed', () {
    final engine = NavigationEngine()..loadRoute(route(northEast));
    expect(engine.effectiveSpeed, NavigationEngine.baseSpeedMps);
  });

  test('2x speed uses twice the base speed', () {
    final engine = NavigationEngine()
      ..setSpeedMultiplier(2);
    expect(engine.effectiveSpeed, NavigationEngine.baseSpeedMps * 2);
  });

  test('5x speed uses five times the base speed', () {
    final engine = NavigationEngine()
      ..setSpeedMultiplier(5);
    expect(engine.effectiveSpeed, NavigationEngine.baseSpeedMps * 5);
  });

  test('remaining distance decreases', () {
    final engine = NavigationEngine()..loadRoute(route(northEast));
    final before = engine.advance(Duration.zero).remainingDistanceMeters;
    final after = engine.advance(const Duration(seconds: 1)).remainingDistanceMeters;
    expect(after, lessThan(before));
  });

  test('remaining duration is distance divided by speed', () {
    final engine = NavigationEngine()..loadRoute(route(northEast));
    final state = engine.advance(const Duration(seconds: 1));
    expect(state.remainingDurationSeconds,
        closeTo(state.remainingDistanceMeters / engine.effectiveSpeed, 0.0001));
  });

  test('route completion is reported after the full route', () {
    final engine = NavigationEngine()..loadRoute(route(northEast));
    expect(engine.advance(const Duration(hours: 1)).isCompleted, isTrue);
  });

  test('north-east bearing is approximately 45 degrees', () {
    expect(
      BearingUtils.bearing(fromLat: 0, fromLng: 0, toLat: 1, toLng: 1),
      closeTo(45, 0.5),
    );
  });

  test('359 to 1 uses the positive shortest delta', () {
    expect(BearingUtils.shortestDelta(359, 1), 2);
  });

  test('1 to 359 uses the negative shortest delta', () {
    expect(BearingUtils.shortestDelta(1, 359), -2);
  });

  test('invalid coordinates never produce NaN output', () {
    final engine = NavigationEngine()
      ..loadRoute(route([const LatLng(double.nan, 0), const LatLng(1, 1)]));
    final state = engine.advance(Duration.zero);
    expect(state.position.latitude.isFinite, isTrue);
    expect(state.position.longitude.isFinite, isTrue);
  });

  test('unevenly spaced points still use constant speed', () {
    final engine = NavigationEngine()
      ..loadRoute(route([
        const LatLng(0, 0),
        const LatLng(0, 0.001),
        const LatLng(0, 0.01),
      ]));
    final first = engine.advance(const Duration(seconds: 1));
    final second = engine.advance(const Duration(seconds: 1));
    expect(
      second.traveledDistanceMeters - first.traveledDistanceMeters,
      closeTo(NavigationEngine.baseSpeedMps, 0.001),
    );
  });
}

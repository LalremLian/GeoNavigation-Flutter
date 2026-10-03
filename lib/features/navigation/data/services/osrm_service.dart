import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/errors/routing_errors.dart';
import '../models/osrm_response.dart';

class OsrmService {
  OsrmService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 10);

  /// Fetches a driving route between origin and destination.
  Future<OsrmResponse> fetchRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final uri = buildRouteUri(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on SocketException catch (e) {
      throw RoutingNetworkError(e.message);
    } on HttpException catch (e) {
      throw RoutingNetworkError(e.message);
    } on TimeoutException {
      throw const RoutingTimeout();
    } catch (e) {
      throw RoutingNetworkError(e.toString());
    }

    if (response.statusCode != 200) {
      throw RoutingNetworkError(
          'HTTP ${response.statusCode}');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const RoutingParseError('Invalid JSON response');
    }

    final osrmResponse = OsrmResponse.fromJson(json);
    if (!osrmResponse.isOk || osrmResponse.routes.isEmpty) {
      throw const NoRouteFound();
    }

    return osrmResponse;
  }

  /// Builds the OSRM route URL.
  Uri buildRouteUri({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) {
    // OSRM expects longitude,latitude order
    final coords = '$originLng,$originLat;$destLng,$destLat';
    return Uri.parse(
      '$baseUrl/route/v1/driving/$coords'
      '?overview=full&geometries=polyline',
    );
  }

  void dispose() {
    _client.close();
  }
}

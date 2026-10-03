import 'app_error.dart';

/// The OSRM server returned no routes for the given coordinates.
final class NoRouteFound extends AppError {
  const NoRouteFound()
      : super('No driving route could be found between these two points.');
}

/// A network-level failure occurred while fetching a route (DNS, socket, etc.).
final class RoutingNetworkError extends AppError {
  const RoutingNetworkError([String detail = ''])
      : super('Network error while fetching route. $detail');
}

/// The route request exceeded the configured timeout.
final class RoutingTimeout extends AppError {
  const RoutingTimeout()
      : super('Route request timed out. Check your connection and try again.');
}

/// The OSRM response was received but could not be parsed into a valid route.
final class RoutingParseError extends AppError {
  const RoutingParseError([String detail = ''])
      : super('Failed to parse routing response. $detail');
}

/// The decoded route contains zero usable points.
final class InvalidRoute extends AppError {
  const InvalidRoute([String detail = ''])
      : super('The route returned by the server is invalid. $detail');
}

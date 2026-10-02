/// Represents the current state of the navigation session.
///
/// Used as the single source of truth for which UI controls are enabled.
enum NavigationStatus {
  /// No route loaded yet; waiting for destination or location.
  idle,

  /// Fetching the user's current location.
  loadingLocation,

  /// Route fetch is in progress.
  loadingRoute,

  /// Route is loaded and ready; navigation has not started.
  ready,

  /// Car is actively moving along the route.
  navigating,

  /// Navigation is paused; car is stationary at current position.
  paused,

  /// Car has reached the destination.
  completed,
}

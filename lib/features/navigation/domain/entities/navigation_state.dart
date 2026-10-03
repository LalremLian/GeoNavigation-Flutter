/// Represents the current state of the navigation session.
enum NavigationStatus {
  idle,
  loadingLocation,
  loadingRoute,
  ready,
  navigating,
  paused,
  completed,
}

/// Base class for all typed application errors.
///
/// Using an abstract class hierarchy. The [AppError] subtypes are defined
/// across multiple files in the errors/ directory.
///
/// Call-sites can switch on [AppError] using pattern matching against
/// the concrete subtypes.
abstract class AppError {
  const AppError(this.message);

  /// Human-readable description — used for logging, not shown raw in the UI.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

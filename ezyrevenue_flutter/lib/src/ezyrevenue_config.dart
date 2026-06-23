/// Log verbosity levels for the EzyRevenue SDK.
enum LogLevel {
  /// No logging output.
  none,

  /// Only errors and warnings are logged.
  error,

  /// Full verbose logging including request/response details.
  verbose,
}

/// Configuration for the EzyRevenue SDK.
///
/// Pass an instance of this class to [EzyRevenue.init] to configure the SDK.
///
/// ```dart
/// await EzyRevenue.init(
///   config: EzyRevenueConfig(
///     apiKey: 'your_api_key',
///     appUserId: 'user-uuid',
///   ),
/// );
/// ```
class EzyRevenueConfig {
  /// The API key for authenticating with the EzyRevenue backend.
  ///
  /// Obtain this from the EzyRevenue dashboard.
  final String apiKey;

  /// The unique identifier for the current app user.
  final String appUserId;

  /// Controls the verbosity of SDK log output. Defaults to [LogLevel.none].
  final LogLevel logLevel;

  /// Optional callback invoked whenever the SDK produces a log message.
  ///
  /// Use this to route SDK logs to your own logging system, show toasts,
  /// or display snackbars — the SDK does not impose any UI.
  ///
  /// ```dart
  /// EzyRevenueConfig(
  ///   apiKey: 'key',
  ///   appUserId: 'user',
  ///   onLog: (msg) => debugPrint('MyApp: $msg'),
  /// );
  /// ```
  final void Function(String message)? onLog;

  /// Creates an [EzyRevenueConfig].
  const EzyRevenueConfig({
    required this.apiKey,
    required this.appUserId,
    this.logLevel = LogLevel.none,
    this.onLog,
  });
}

import 'package:flutter/foundation.dart';
import 'ezyrevenue_config.dart';

/// Internal logger for the EzyRevenue SDK.
///
/// Routes messages through [debugPrint] and the optional [onLog] callback
/// based on the configured [LogLevel].
class EzyRevenueLogger {
  final LogLevel _level;
  final void Function(String message)? _onLog;

  /// Creates a logger with the given [level] and optional [onLog] callback.
  const EzyRevenueLogger({
    required LogLevel level,
    void Function(String message)? onLog,
  })  : _level = level,
        _onLog = onLog;

  /// A no-op logger that silences all output.
  static const EzyRevenueLogger silent = EzyRevenueLogger(level: LogLevel.none);

  /// Logs a verbose message. Only printed in debug/profile mode when [LogLevel.verbose] is active.
  /// Always silenced in release mode to prevent exposing tokens or sensitive headers.
  void verbose(String message) {
    if (_level == LogLevel.verbose && !kReleaseMode) {
      _emit(message);
    }
  }

  /// Logs an error message. Printed when [LogLevel.error] or above is active.
  void error(String message) {
    if (_level == LogLevel.error || _level == LogLevel.verbose) {
      _emit('ERROR: $message');
    }
  }

  void _emit(String message) {
    final formatted = '[EzyRevenue] $message';
    debugPrint(formatted);
    _onLog?.call(formatted);
  }
}

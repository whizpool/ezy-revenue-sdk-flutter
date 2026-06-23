import 'package:shared_preferences/shared_preferences.dart';
import 'ezyrevenue_logger.dart';

/// Persists and restores EzyRevenue login sessions using [SharedPreferences].
///
/// All keys are prefixed with `ezyrevenue_` to avoid collisions with the
/// host app's own preferences.
class EzyRevenueSessionStorage {
  static const String _keyUserId = 'ezyrevenue_app_user_id';
  static const String _keyAccessToken = 'ezyrevenue_app_access_token';
  static const String _keyTimestamp = 'ezyrevenue_session_timestamp';

  final EzyRevenueLogger _logger;

  /// Creates a session storage instance.
  const EzyRevenueSessionStorage({required EzyRevenueLogger logger})
      : _logger = logger;

  /// Saves a login session to local storage.
  Future<void> saveSession({
    required String appUserId,
    required String accessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, appUserId);
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setInt(
      _keyTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
    _logger.verbose('Session saved for user: $appUserId');
  }

  /// Loads a previously saved session, or returns `null` if none exists.
  Future<EzyRevenueSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    final accessToken = prefs.getString(_keyAccessToken);
    final timestamp = prefs.getInt(_keyTimestamp);

    if (userId != null && accessToken != null && timestamp != null) {
      _logger.verbose('Restored session for user: $userId');
      return EzyRevenueSession(
        appUserId: userId,
        accessToken: accessToken,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
    }

    _logger.verbose('No saved session found.');
    return null;
  }

  /// Returns `true` if a valid session exists for the given [appUserId].
  Future<bool> hasValidSession(String appUserId) async {
    final session = await loadSession();
    return session != null && session.appUserId == appUserId;
  }

  /// Clears the saved session from local storage.
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyTimestamp);
    _logger.verbose('Session cleared.');
  }
}

/// Represents a persisted login session.
class EzyRevenueSession {
  /// The user ID associated with this session.
  final String appUserId;

  /// The access token received from the server.
  final String accessToken;

  /// When this session was created.
  final DateTime timestamp;

  /// Creates an [EzyRevenueSession].
  const EzyRevenueSession({
    required this.appUserId,
    required this.accessToken,
    required this.timestamp,
  });
}

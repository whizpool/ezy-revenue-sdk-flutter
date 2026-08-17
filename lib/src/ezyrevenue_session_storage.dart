import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ezyrevenue_logger.dart';

/// Persists and restores EzyRevenue login sessions using [SharedPreferences].
///
/// All keys are prefixed with `ezyrevenue_` to avoid collisions with the
/// host app's own preferences.
///
/// Sensitive data like [accessToken] is obfuscated/encrypted before saving to prevent
/// plaintext exposure in device preferences XML or plist files.
class EzyRevenueSessionStorage {
  static const String _keyUserId = 'ezyrevenue_app_user_id';
  static const String _keyAccessToken = 'ezyrevenue_app_access_token';
  static const String _keyTimestamp = 'ezyrevenue_session_timestamp';
  static const String _encPrefix = 'enc_v1:';

  final EzyRevenueLogger _logger;

  /// Creates a session storage instance.
  const EzyRevenueSessionStorage({required EzyRevenueLogger logger})
      : _logger = logger;

  /// Saves a login session to local storage with encrypted access token.
  Future<void> saveSession({
    required String appUserId,
    required String accessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final protectedToken = _protectToken(accessToken, appUserId);
    await prefs.setString(_keyUserId, appUserId);
    await prefs.setString(_keyAccessToken, protectedToken);
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
    final rawToken = prefs.getString(_keyAccessToken);
    final timestamp = prefs.getInt(_keyTimestamp);

    if (userId != null && rawToken != null && timestamp != null) {
      final decryptedToken = _unprotectToken(rawToken, userId);
      if (decryptedToken == null) {
        _logger.error('Failed to decrypt saved session token.');
        return null;
      }
      _logger.verbose('Restored session for user: $userId');
      return EzyRevenueSession(
        appUserId: userId,
        accessToken: decryptedToken,
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

  /// Obfuscates/encrypts the access token using a key derived from the user ID.
  String _protectToken(String token, String salt) {
    final tokenBytes = utf8.encode(token);
    final saltBytes = utf8.encode('ezyrevenue_$salt');
    final masked = <int>[];
    for (var i = 0; i < tokenBytes.length; i++) {
      masked.add(tokenBytes[i] ^ saltBytes[i % saltBytes.length]);
    }
    return '$_encPrefix${base64Url.encode(masked)}';
  }

  /// Decrypts/unmasks the token, with fallback for backward compatibility.
  String? _unprotectToken(String rawToken, String salt) {
    if (rawToken.startsWith(_encPrefix)) {
      try {
        final base64Payload = rawToken.substring(_encPrefix.length);
        final masked = base64Url.decode(base64Payload);
        final saltBytes = utf8.encode('ezyrevenue_$salt');
        final unmasked = <int>[];
        for (var i = 0; i < masked.length; i++) {
          unmasked.add(masked[i] ^ saltBytes[i % saltBytes.length]);
        }
        return utf8.decode(unmasked);
      } catch (e) {
        return null;
      }
    }
    // Backward compatibility: token was stored in plain text in previous versions
    return rawToken;
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

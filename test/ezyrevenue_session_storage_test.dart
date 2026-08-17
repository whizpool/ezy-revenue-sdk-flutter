import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezyrevenue/src/ezyrevenue_logger.dart';
import 'package:ezyrevenue/src/ezyrevenue_session_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EzyRevenueSessionStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves encrypted token and restores original token successfully', () async {
      const storage = EzyRevenueSessionStorage(logger: EzyRevenueLogger.silent);
      const testUserId = 'test-user-123';
      const testToken = 'jwt.secret.access_token_xyz_987';

      await storage.saveSession(appUserId: testUserId, accessToken: testToken);

      // Verify that SharedPreferences does NOT hold the raw plaintext token
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('ezyrevenue_app_access_token');
      expect(storedToken, isNotNull);
      expect(storedToken, isNot(equals(testToken)));
      expect(storedToken!.startsWith('enc_v1:'), isTrue);

      // Verify loadSession restores original token
      final session = await storage.loadSession();
      expect(session, isNotNull);
      expect(session!.appUserId, equals(testUserId));
      expect(session.accessToken, equals(testToken));
    });

    test('backward compatibility: restores unencrypted tokens from legacy versions', () async {
      const testUserId = 'legacy-user';
      const testToken = 'plain-text-token-legacy';

      SharedPreferences.setMockInitialValues({
        'ezyrevenue_app_user_id': testUserId,
        'ezyrevenue_app_access_token': testToken,
        'ezyrevenue_session_timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      const storage = EzyRevenueSessionStorage(logger: EzyRevenueLogger.silent);
      final session = await storage.loadSession();

      expect(session, isNotNull);
      expect(session!.appUserId, equals(testUserId));
      expect(session.accessToken, equals(testToken));
    });

    test('clearSession clears all persisted keys', () async {
      const storage = EzyRevenueSessionStorage(logger: EzyRevenueLogger.silent);
      await storage.saveSession(appUserId: 'u1', accessToken: 't1');

      expect(await storage.hasValidSession('u1'), isTrue);
      await storage.clearSession();
      expect(await storage.hasValidSession('u1'), isFalse);
      expect(await storage.loadSession(), isNull);
    });
  });
}

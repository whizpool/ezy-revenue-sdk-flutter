import 'package:flutter_test/flutter_test.dart';
import 'package:ezyrevenue/src/ezyrevenue_config.dart';
import 'package:ezyrevenue/src/ezyrevenue_logger.dart';

void main() {
  group('EzyRevenueLogger', () {
    test('silent logger does not invoke onLog', () {
      var called = false;
      final logger = EzyRevenueLogger(
        level: LogLevel.none,
        onLog: (_) => called = true,
      );

      logger.verbose('verbose test');
      logger.error('error test');

      expect(called, isFalse);
    });

    test('error level logger only invokes onLog for error messages', () {
      final logs = <String>[];
      final logger = EzyRevenueLogger(
        level: LogLevel.error,
        onLog: (msg) => logs.add(msg),
      );

      logger.verbose('verbose msg');
      expect(logs, isEmpty);

      logger.error('critical failure');
      expect(logs.length, equals(1));
      expect(logs.first, contains('ERROR: critical failure'));
    });

    test('verbose level logger invokes onLog for all messages in debug', () {
      final logs = <String>[];
      final logger = EzyRevenueLogger(
        level: LogLevel.verbose,
        onLog: (msg) => logs.add(msg),
      );

      logger.verbose('login response body: {"token": "123"}');
      logger.error('some error');

      expect(logs.length, equals(2));
      expect(logs[0], contains('login response body'));
      expect(logs[1], contains('ERROR: some error'));
    });
  });
}

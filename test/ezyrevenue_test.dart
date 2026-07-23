import 'package:flutter_test/flutter_test.dart';
import 'package:ezyrevenue/ezyrevenue_platform_interface.dart';
import 'package:ezyrevenue/ezyrevenue_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEzyRevenuePlatform extends EzyRevenuePlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final EzyRevenuePlatform initialPlatform = EzyRevenuePlatform.instance;

  test('$MethodChannelEzyRevenue is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEzyRevenue>());
  });

  test('getPlatformVersion via mock platform', () async {
    MockEzyRevenuePlatform fakePlatform = MockEzyRevenuePlatform();
    EzyRevenuePlatform.instance = fakePlatform;

    expect(await fakePlatform.getPlatformVersion(), '42');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_cat_replica/revenue_cat_replica.dart';
import 'package:revenue_cat_replica/revenue_cat_replica_platform_interface.dart';
import 'package:revenue_cat_replica/revenue_cat_replica_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockRevenueCatReplicaPlatform
    with MockPlatformInterfaceMixin
    implements RevenueCatReplicaPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final RevenueCatReplicaPlatform initialPlatform = RevenueCatReplicaPlatform.instance;

  test('$MethodChannelRevenueCatReplica is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRevenueCatReplica>());
  });

  test('getPlatformVersion', () async {
    RevenueCatReplica revenueCatReplicaPlugin = RevenueCatReplica();
    MockRevenueCatReplicaPlatform fakePlatform = MockRevenueCatReplicaPlatform();
    RevenueCatReplicaPlatform.instance = fakePlatform;

    expect(await revenueCatReplicaPlugin.getPlatformVersion(), '42');
  });
}

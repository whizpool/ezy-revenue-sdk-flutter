import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'revenue_cat_replica_method_channel.dart';

abstract class RevenueCatReplicaPlatform extends PlatformInterface {
  /// Constructs a RevenueCatReplicaPlatform.
  RevenueCatReplicaPlatform() : super(token: _token);

  static final Object _token = Object();

  static RevenueCatReplicaPlatform _instance = MethodChannelRevenueCatReplica();

  /// The default instance of [RevenueCatReplicaPlatform] to use.
  ///
  /// Defaults to [MethodChannelRevenueCatReplica].
  static RevenueCatReplicaPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RevenueCatReplicaPlatform] when
  /// they register themselves.
  static set instance(RevenueCatReplicaPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> getCountryCode() {
    throw UnimplementedError('getCountryCode() has not been implemented.');
  }

  Future<bool> purchaseProduct(String productIdentifier, {String? appUserId}) {
    throw UnimplementedError('purchaseProduct() has not been implemented.');
  }

  Future<List<Map<String, dynamic>>> getProducts(List<String> productIdentifiers) {
    throw UnimplementedError('getProducts() has not been implemented.');
  }

  Future<String?> getAppVersion() {
    throw UnimplementedError('getAppVersion() has not been implemented.');
  }
}

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ezyrevenue_method_channel.dart';

abstract class EzyRevenuePlatform extends PlatformInterface {
  /// Constructs a EzyRevenuePlatform.
  EzyRevenuePlatform() : super(token: _token);

  static final Object _token = Object();

  static EzyRevenuePlatform _instance = MethodChannelEzyRevenue();

  /// The default instance of [EzyRevenuePlatform] to use.
  ///
  /// Defaults to [MethodChannelEzyRevenue].
  static EzyRevenuePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EzyRevenuePlatform] when
  /// they register themselves.
  static set instance(EzyRevenuePlatform instance) {
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

  Future<void> checkUnacknowledgedPurchases() {
    throw UnimplementedError('checkUnacknowledgedPurchases() has not been implemented.');
  }
}

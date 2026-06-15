import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'revenue_cat_replica_platform_interface.dart';

/// An implementation of [RevenueCatReplicaPlatform] that uses method channels.
class MethodChannelRevenueCatReplica extends RevenueCatReplicaPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('revenue_cat_replica');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<String?> getCountryCode() async {
    final country = await methodChannel.invokeMethod<String>(
      'getCountryCode',
    );
    return country;
  }

  @override
  Future<bool> purchaseProduct(String productIdentifier, {String? appUserId}) async {

    print("appuserid");
    print(appUserId);
    final success = await methodChannel.invokeMethod<bool>(
      'purchaseProduct',
      {
        'productIdentifier': productIdentifier,
        'appUserId': appUserId,
      },
    );
    return success ?? false;
  }

  @override
  Future<List<Map<String, dynamic>>> getProducts(List<String> productIdentifiers) async {
    final products = await methodChannel.invokeMethod<List<dynamic>>(
      'getProducts',
      {
        'productIdentifiers': productIdentifiers,
      },
    );
    return products?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
  }

  @override
  Future<String?> getAppVersion() async {
    return await methodChannel.invokeMethod<String>('getAppVersion');
  }
}

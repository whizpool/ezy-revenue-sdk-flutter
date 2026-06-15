// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'revenue_cat_replica_platform_interface.dart';

/// A web implementation of the RevenueCatReplicaPlatform of the RevenueCatReplica plugin.
class RevenueCatReplicaWeb extends RevenueCatReplicaPlatform {
  /// Constructs a RevenueCatReplicaWeb
  RevenueCatReplicaWeb();

  static void registerWith(Registrar registrar) {
    RevenueCatReplicaPlatform.instance = RevenueCatReplicaWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  @override
  Future<String?> getCountryCode() async {
    // In web, we try to extract it from the locale (e.g., 'en-PK' -> 'PK')
    final locale = web.window.navigator.language;
    if (locale.contains('-')) {
      return locale.split('-').last.toUpperCase();
    }
    return null;
  }

  @override
  Future<bool> purchaseProduct(String productIdentifier) async {
    // Web implementation of purchase could be a redirect to a payment page
    // or not supported if it's strictly for mobile stores.
    print('Purchase not implemented for web: $productIdentifier');
    return false;
  }
}

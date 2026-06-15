import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'revenue_cat_replica_platform_interface.dart';
import 'revenue_cat_replica_models.dart';
import 'dart:io';
export 'revenue_cat_replica_models.dart';

class RevenueCatReplica {
  static const String _baseUrl = 'http://192.168.0.249:3000';
  static const String sdkVersion = '0.0.1';

  String? _apiKey;
  String? androidApiKey;
  String? iosApiKey;
  String? _appUserId;
  String? _appAccessToken;
  Offering? current;
  List<Offering> offeringsList = [];

  void configure({String? androidApiKey, String? iosApiKey}) {
    this.androidApiKey = androidApiKey;
    this.iosApiKey = iosApiKey;
    _apiKey = Platform.isIOS ? iosApiKey : androidApiKey;
  }

  Future<String?> getCountryCodeFromIP() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['countryCode'];
        }
      }
    } catch (e) {
      debugPrint("Failed to get country code from IP: $e");
    }
    return null;
  }

  Future<String?> getPlatformVersion() {
    return RevenueCatReplicaPlatform.instance.getPlatformVersion();
  }

  Future<bool?> showToast(String message) {
    return Fluttertoast.showToast(msg: message);
  }

  Future<http.Response> login(String appUserId) async {
    if (_apiKey == null) {
      showToast("Error: API Key not configured. Call configure() first.");
      throw Exception("API Key is null. Call configure() first.");
    }

    try {
      final url = Uri.parse('$_baseUrl/v1/auth/login');
      
      final platformVersion = await getPlatformVersion() ?? "unknown";
      final appVersion = "1.0.0";
      final locale = ui.PlatformDispatcher.instance.locale.toString().replaceAll('_', '-');
      final sdkVersionHeader = "flutter (${Platform.isIOS ? 'iOS' : 'Android'} SDK $sdkVersion)";

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'x-sdk-version': sdkVersionHeader,
        'x-app-version': appVersion,
        'x-device-locale': locale,
        'x-platform-version': platformVersion,
      };
      print('Login Request Headers: $headers');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'appUserId': appUserId}),
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Headers: ${response.headers}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        _appUserId = appUserId;
        _appAccessToken = responseData['appAccessToken'];
        showToast("Login Successful!");
      } else {
        showToast("Login Failed: ${response.statusCode}");
      }
      return response;
    } catch (e) {
      showToast("Error: $e");
      rethrow;
    }
  }

  Future<List<Offering>> getOfferings() async {
    if (_apiKey == null) {
      showToast("Error: API Key not configured.");
      throw Exception("API Key is null.");
    }
    if (_appUserId == null) {
      showToast("Error: No appUserId. Please login first.");
      throw Exception("appUserId is null. Call login() first.");
    }

    try {
      final String effectiveCountry = await getCountryCodeFromIP() ?? 'US';

      final url = Uri.parse('$_baseUrl/v1/subscribers/$_appUserId/offerings?country=$effectiveCountry');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

      if (_appAccessToken != null) {
        headers['x-app-access-token'] = _appAccessToken!;
      }

      print('GetOfferings Request URL: $url');
      print('GetOfferings Request Headers: $headers');

      final response = await http.get(url, headers: headers);

      print('GetOfferings Response Status: ${response.statusCode}');
      print('GetOfferings Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final offeringsResponse = OfferingsResponse.fromJson(data);

        offeringsList = offeringsResponse.offerings;

        // Update price and currency from store
        try {
          final allProducts = offeringsList
              .expand((offering) => offering.packages)
              .expand((package) => package.products)
              .toList();
          
          if (allProducts.isNotEmpty) {
            await _syncProductsWithStore(allProducts);
          }
        } catch (e) {
          debugPrint("Failed to update prices from store: $e");
        }
        
        // Find the default offering and set it to 'current'
        try {
          current = offeringsList.firstWhere((offering) => offering.isDefault);
        } catch (e) {
          current = null;
        }

        showToast("Offerings Loaded!");
        return offeringsList;
      } else {
        showToast("Offerings Failed: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      showToast("Error: $e");
      rethrow;
    }
  }

  Future<void> purchasePackage(Package package, {String? offeringId}) async {
    Platform.isIOS ? purchasePackageIOS(package) : purchasePackageAndroid(package);
  }

  Future<void> purchaseProduct(String productIdentifier) async {
    try {
      print("Starting purchase for product: $productIdentifier");
      final bool success = await RevenueCatReplicaPlatform.instance
          .purchaseProduct(productIdentifier, appUserId: _appUserId);

      print("Native purchase result: $success");
      if (success) {
        showToast("Purchase Successful!");
      } else {
        showToast("Purchase cancelled or failed.");
      }
    } catch (e) {
      print("Error in purchaseProduct: $e");
      showToast("Error during purchase: $e");
    }
  }

  Future<List<Product>> getProducts() async {
    if (_apiKey == null) {
      showToast("Error: API Key not configured.");
      throw Exception("API Key is null.");
    }

    try {
      final url = Uri.parse('$_baseUrl/v1/products');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

      print('GetProducts Request URL: $url');
      final response = await http.get(
        url,
        headers: headers,
      );

      print('GetProducts Response Status: ${response.statusCode}');
      print('GetProducts Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        List<dynamic>? productsData;

        if (responseData is List) {
          productsData = responseData;
        } else if (responseData is Map) {
          productsData = responseData['data'] as List? ?? responseData['products'] as List?;
        }

        if (productsData == null) {
          print("Could not find products list in response: $responseData");
          return [];
        }

        final List<Product> products = productsData.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();

        if (products.isNotEmpty) {
          await _syncProductsWithStore(products);
        }
        return products;
      } else {
        showToast("Products Failed: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching product details: $e");
      return [];
    }
  }

  Future<void> purchasePackageAndroid(Package package, {String? offeringId}) async {
    try {
      print("Starting purchase for product: ${package.platformProductIdentifier}");
      final bool success = await RevenueCatReplicaPlatform.instance
          .purchaseProduct(package.products[0].googleSubscriptionId!, appUserId: _appUserId);
      
      print("Native purchase result: $success");
      if (success) {
        showToast("Purchase Successful!");
        // await purchase(package.products[0].googleSubscriptionId!, offeringId: offeringId);
      } else {
        showToast("Purchase cancelled or failed.");
      }
    } catch (e) {
      print("Error in purchasePackage: $e");
      showToast("Error during purchase: $e");
    }
  }

  Future<void> purchasePackageIOS(Package package, {String? offeringId}) async {
    try {
      final productId = package.platformProductIdentifier;
      print("Starting iOS purchase for product: $productId");
      final bool success = await RevenueCatReplicaPlatform.instance
          .purchaseProduct(productId, appUserId: _appUserId);
      
      print("Native iOS purchase result: $success");
      if (success) {
        showToast("Purchase Successful!");
        // await purchase(productId, offeringId: offeringId);
      } else {
        showToast("Purchase cancelled or failed.");
      }
    } catch (e) {
      print("Error in purchasePackageIOS: $e");
      showToast("Error during purchase: $e");
    }
  }

  Future<void> _syncProductsWithStore(List<Product> products) async {
    final storeProductIds = products.map((product) {
      if (Platform.isAndroid) {
        return product.googleSubscriptionId ?? product.identifier;
      } else {
        return product.identifier;
      }
    }).whereType<String>().toSet().toList();

    if (storeProductIds.isEmpty) return;

    try {
      final storeProducts = await RevenueCatReplicaPlatform.instance.getProducts(storeProductIds);
      for (var product in products) {
        final productIdToMatch = Platform.isAndroid 
            ? (product.googleSubscriptionId ?? product.identifier) 
            : product.identifier;

        final storeProduct = storeProducts.firstWhere(
          (sp) => sp['identifier'] == productIdToMatch,
          orElse: () => {},
        );
        if (storeProduct.isNotEmpty && storeProduct['priceAmountMicros'] != null) {
          product.price = Price(
            amount: storeProduct['priceAmountMicros'],
            currency: storeProduct['priceCurrencyCode'],
          );
        }
      }
    } catch (e) {
      debugPrint("Error syncing products with store: $e");
    }
  }

  Future<Map<String, dynamic>> getSubscriber() async {
    if (_apiKey == null) {
      showToast("Error: API Key not configured.");
      throw Exception("API Key is null.");
    }
    if (_appUserId == null) {
      showToast("Error: No appUserId. Please login first.");
      throw Exception("appUserId is null. Call login() first.");
    }

    try {
      final url = Uri.parse('$_baseUrl/v1/subscribers/$_appUserId');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };
      
      if (_appAccessToken != null) {
        headers['x-app-access-token'] = _appAccessToken!;
      }

      print('GetSubscriber Request URL: $url');
      final response = await http.get(url, headers: headers);

      print('GetSubscriber Response Status: ${response.statusCode}');
      print('GetSubscriber Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        showToast("Failed to get subscriber: ${response.statusCode}");
        return {};
      }
    } catch (e) {
      showToast("Error getting subscriber: $e");
      rethrow;
    }
  }
}

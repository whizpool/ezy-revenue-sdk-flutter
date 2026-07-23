import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;

import 'ezyrevenue_logger.dart';
import 'models/models.dart';

/// Internal HTTP client for communicating with the EzyRevenue backend API.
///
/// This class is not part of the public API. Consumers interact with
/// [EzyRevenue] instead.
class EzyRevenueApi {
  static const String _baseUrl = 'https://api-ezyrevenue.doctors-finder.com';
  static const String _sdkVersion = '0.0.1';

  final String _apiKey;
  final EzyRevenueLogger _logger;

  /// Creates an API client with the given [apiKey] and [logger].
  EzyRevenueApi({
    required String apiKey,
    required EzyRevenueLogger logger,
  })  : _apiKey = apiKey,
        _logger = logger;

  /// Common headers sent with every request.
  Map<String, String> _baseHeaders({String? accessToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };
    if (accessToken != null) {
      headers['x-app-access-token'] = accessToken;
    }
    return headers;
  }

  /// Builds platform-specific headers for authentication requests.
  Future<Map<String, String>> _authHeaders({
    required String platformVersion,
  }) async {
    final locale = ui.PlatformDispatcher.instance.locale
        .toString()
        .replaceAll('_', '-');
    final sdkVersionHeader =
        'flutter (${Platform.isIOS ? 'iOS' : 'Android'} SDK $_sdkVersion)';

    return {
      ..._baseHeaders(),
      'x-sdk-version': sdkVersionHeader,
      'x-app-version': '1.0.0',
      'x-device-locale': locale,
      'x-platform-version': platformVersion,
    };
  }

  /// Authenticates a user and returns the access token.
  ///
  /// Returns the `appAccessToken` string on success, or `null` on failure.
  Future<String?> login({
    required String appUserId,
    required String platformVersion,
  }) async {
    final url = Uri.parse('$_baseUrl/v1/auth/login');
    final headers = await _authHeaders(platformVersion: platformVersion);

    _logger.verbose('Login → POST $url');
    _logger.verbose('Login headers: $headers');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'appUserId': appUserId}),
    );

    _logger.verbose('Login ← ${response.statusCode}');
    _logger.verbose('Login body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['appAccessToken'] as String?;
    }

    _logger.error('Login failed with status ${response.statusCode}');
    return null;
  }

  /// Fetches available offerings for a subscriber.
  Future<OfferingsResponse?> fetchOfferings({
    required String appUserId,
    String? accessToken,
    required String countryCode,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/v1/subscribers/$appUserId/offerings?country=$countryCode',
    );
    final headers = _baseHeaders(accessToken: accessToken);

    _logger.verbose('GetOfferings → GET $url');

    final response = await http.get(url, headers: headers);

    _logger.verbose('GetOfferings ← ${response.statusCode}');
    _logger.verbose('GetOfferings body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return OfferingsResponse.fromJson(data);
    }

    _logger.error('GetOfferings failed with status ${response.statusCode}');
    return null;
  }

  /// Fetches all products.
  Future<List<Product>> fetchProducts() async {
    final url = Uri.parse('$_baseUrl/v1/products');
    final headers = _baseHeaders();

    _logger.verbose('GetProducts → GET $url');

    final response = await http.get(url, headers: headers);

    _logger.verbose('GetProducts ← ${response.statusCode}');
    _logger.verbose('GetProducts body: ${response.body}');

    if (response.statusCode == 200) {
      final dynamic responseData = jsonDecode(response.body);
      List<dynamic>? productsData;

      if (responseData is List) {
        productsData = responseData;
      } else if (responseData is Map) {
        productsData =
            responseData['data'] as List? ?? responseData['products'] as List?;
      }

      if (productsData == null) {
        _logger.error('Could not find products list in response: $responseData');
        return [];
      }

      return productsData
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    _logger.error('GetProducts failed with status ${response.statusCode}');
    return [];
  }

  /// Fetches subscriber entitlements and subscription status.
  Future<Map<String, dynamic>> fetchSubscriber({
    required String appUserId,
    String? accessToken,
  }) async {
    final url = Uri.parse('$_baseUrl/v1/subscribers/$appUserId');
    final headers = _baseHeaders(accessToken: accessToken);

    _logger.verbose('GetSubscriber → GET $url');

    final response = await http.get(url, headers: headers);

    _logger.verbose('GetSubscriber ← ${response.statusCode}');
    _logger.verbose('GetSubscriber body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    _logger.error('GetSubscriber failed with status ${response.statusCode}');
    return {};
  }

  /// Queries the country code from an IP geolocation service.
  Future<String?> fetchCountryCodeFromIP() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          return data['countryCode'] as String?;
        }
      }
    } catch (e) {
      _logger.error('Failed to get country code from IP: $e');
    }
    return null;
  }
}

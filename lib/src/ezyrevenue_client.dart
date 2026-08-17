import 'package:flutter/foundation.dart';

import 'ezyrevenue_api.dart';
import 'ezyrevenue_config.dart';
import 'ezyrevenue_logger.dart';
import 'ezyrevenue_session_storage.dart';
import 'models/models.dart';
import '../ezyrevenue_platform_interface.dart';

/// The main entry point for the EzyRevenue SDK.
///
/// Use [EzyRevenue.init] to initialize the SDK, then access the singleton
/// via [EzyRevenue.instance].
///
/// ## Quick Start
///
/// ```dart
/// // Initialize once at app startup
/// await EzyRevenue.init(
///   config: EzyRevenueConfig(
///     apiKey: 'your_api_key',
///     appUserId: 'user-uuid',
///     logLevel: LogLevel.verbose,
///   ),
/// );
///
/// // Use anywhere in your app
/// final offerings = await EzyRevenue.instance.getOfferings();
/// ```
///
/// See also:
/// - [EzyRevenueConfig] for all initialization options.
/// - [Offering] and [Package] for displaying paywalls.
/// - [Product] for available purchase items.
class EzyRevenue {
  static EzyRevenue? _instance;

  final EzyRevenueConfig _config;
  final EzyRevenueApi _api;
  final EzyRevenueLogger _logger;
  final EzyRevenueSessionStorage _sessionStorage;

  String? _appAccessToken;
  List<Offering> _offerings = [];

  /// The currently active offering, or `null` if none has been set.
  Offering? currentOffering;

  // ── Private constructor ─────────────────────────────────────────────

  EzyRevenue._({
    required EzyRevenueConfig config,
    required EzyRevenueApi api,
    required EzyRevenueLogger logger,
    required EzyRevenueSessionStorage sessionStorage,
  })  : _config = config,
        _api = api,
        _logger = logger,
        _sessionStorage = sessionStorage;

  // ── Singleton Accessor ──────────────────────────────────────────────

  /// Returns the initialized singleton instance.
  ///
  /// Throws a [StateError] if [init] has not been called first.
  static EzyRevenue get instance {
    if (_instance == null) {
      throw StateError(
        'EzyRevenue has not been initialized. Call EzyRevenue.init() first.',
      );
    }
    return _instance!;
  }

  /// Returns `true` if the SDK has been initialized.
  static bool get isInitialized => _instance != null;

  // ── Initialization ──────────────────────────────────────────────────

  /// The current version of the SDK.
  static const String sdkVersion = '0.0.3';

  /// Initializes the EzyRevenue SDK.
  ///
  /// This must be called before accessing [instance] or any SDK methods.
  /// Subsequent calls will re-initialize the SDK with the new configuration.
  ///
  /// ```dart
  /// await EzyRevenue.init(
  ///   config: EzyRevenueConfig(
  ///     apiKey: 'your_api_key',
  ///     appUserId: 'user-123',
  ///   ),
  /// );
  /// ```
  static Future<void> init({required EzyRevenueConfig config}) async {
    final logger = EzyRevenueLogger(
      level: config.logLevel,
      onLog: config.onLog,
    );

    final api = EzyRevenueApi(
      apiKey: config.apiKey,
      logger: logger,
    );

    final sessionStorage = EzyRevenueSessionStorage(logger: logger);

    final sdk = EzyRevenue._(
      config: config,
      api: api,
      logger: logger,
      sessionStorage: sessionStorage,
    );

    logger.verbose('Initializing EzyRevenue SDK v$sdkVersion...');

    // Check for a cached session matching this appUserId
    final hasValidSession =
        await sdk._sessionStorage.hasValidSession(config.appUserId);

    if (hasValidSession) {
      final session = await sdk._sessionStorage.loadSession();
      sdk._appAccessToken = session!.accessToken;
      sdk._logger.verbose('Restored cached session — skipping network login.');
    } else {
      // No cached session — perform a fresh login
      sdk._logger.verbose('No cached session found — logging in...');
      await sdk._performLogin();
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await EzyRevenuePlatform.instance.checkUnacknowledgedPurchases();
      } catch (e) {
        sdk._logger.error('Error checking unacknowledged purchases: $e');
      }
    }

    _instance = sdk;
    sdk._logger.verbose('EzyRevenue SDK initialized successfully.');
  }

  /// Internal login flow that authenticates and persists the session.
  Future<void> _performLogin() async {
    final platformVersion =
        await EzyRevenuePlatform.instance.getPlatformVersion() ?? 'unknown';

    final accessToken = await _api.login(
      appUserId: _config.appUserId,
      platformVersion: platformVersion,
    );

    if (accessToken != null) {
      _appAccessToken = accessToken;
      await _sessionStorage.saveSession(
        appUserId: _config.appUserId,
        accessToken: accessToken,
      );
      _logger.verbose('Login successful. Session saved.');
    } else {
      _logger.error('Login failed. Proceeding without access token.');
    }
  }

  // ── Public API ──────────────────────────────────────────────────────

  /// The configured app user ID.
  String get appUserId => _config.appUserId;

  /// Whether the SDK currently holds a valid access token.
  bool get isAuthenticated => _appAccessToken != null;

  /// Fetches the available offerings for the current subscriber.
  ///
  /// On success, caches the result in [offerings] and sets
  /// [currentOffering] to the default offering (if one exists).
  ///
  /// Returns the list of [Offering]s, or an empty list on failure.
  Future<List<Offering>> getOfferings() async {
    final countryCode = await _api.fetchCountryCodeFromIP() ?? 'US';

    final response = await _api.fetchOfferings(
      appUserId: _config.appUserId,
      accessToken: _appAccessToken,
      countryCode: countryCode,
    );

    if (response == null) return [];

    _offerings = response.offerings;

    // Sync prices with the native store
    try {
      final allProducts = _offerings
          .expand((offering) => offering.packages)
          .expand((package) => package.products)
          .toList();

      if (allProducts.isNotEmpty) {
        await _syncProductsWithStore(allProducts);
      }
    } catch (e) {
      _logger.error('Failed to sync prices from store: $e');
    }

    // Set the default offering
    try {
      currentOffering = _offerings.firstWhere((offering) => offering.isDefault);
    } catch (_) {
      currentOffering = null;
    }

    _logger.verbose(
      'Loaded ${_offerings.length} offering(s). '
      'Default: ${currentOffering?.identifier ?? "none"}',
    );

    return _offerings;
  }

  /// Fetches all products configured on the server.
  ///
  /// Prices are synced with the native store automatically.
  Future<List<Product>> getProducts() async {
    final products = await _api.fetchProducts();

    if (products.isNotEmpty) {
      await _syncProductsWithStore(products);
    }

    return products;
  }

  /// Fetches subscriber entitlements and subscription info.
  ///
  /// Returns the raw JSON response map, or an empty map on failure.
  Future<Map<String, dynamic>> getSubscriber() async {
    return _api.fetchSubscriber(
      appUserId: _config.appUserId,
      accessToken: _appAccessToken,
    );
  }

  /// Purchases the given [package].
  ///
  /// Automatically routes to the correct native purchase flow based on
  /// the current platform (iOS or Android).
  Future<bool> purchasePackage(Package package) async {
    return (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
        ? _purchasePackageIOS(package)
        : _purchasePackageAndroid(package);
  }

  /// Purchases a product by its native store identifier.
  Future<bool> purchaseProduct(String productIdentifier) async {
    try {
      _logger.verbose('Purchasing product: $productIdentifier');
      final success = await EzyRevenuePlatform.instance.purchaseProduct(
        productIdentifier,
        appUserId: _config.appUserId,
      );
      _logger.verbose('Purchase result: $success');
      return success;
    } catch (e) {
      _logger.error('Error in purchaseProduct: $e');
      return false;
    }
  }

  /// Clears the persisted session and resets the SDK state.
  ///
  /// After calling this, you must call [EzyRevenue.init] again to
  /// re-initialize the SDK.
  Future<void> logout() async {
    _logger.verbose('Logging out user: ${_config.appUserId}');
    await _sessionStorage.clearSession();
    _appAccessToken = null;
    _offerings = [];
    currentOffering = null;
    _instance = null;
    _logger.verbose('Logout complete. SDK reset.');
  }

  /// Gets the platform version from the native platform channel.
  Future<String?> getPlatformVersion() {
    return EzyRevenuePlatform.instance.getPlatformVersion();
  }

  // ── Private helpers ─────────────────────────────────────────────────

  Future<bool> _purchasePackageAndroid(Package package) async {
    try {
      final productId = package.products.isNotEmpty
          ? package.products[0].googleSubscriptionId ??
              package.platformProductIdentifier
          : package.platformProductIdentifier;

      _logger.verbose('Android purchase for product: $productId');
      final success = await EzyRevenuePlatform.instance.purchaseProduct(
        productId,
        appUserId: _config.appUserId,
      );
      _logger.verbose('Android purchase result: $success');
      return success;
    } catch (e) {
      _logger.error('Error in Android purchase: $e');
      return false;
    }
  }

  Future<bool> _purchasePackageIOS(Package package) async {
    try {
      final productId = package.platformProductIdentifier;
      _logger.verbose('iOS purchase for product: $productId');
      final success = await EzyRevenuePlatform.instance.purchaseProduct(
        productId,
        appUserId: _config.appUserId,
      );
      _logger.verbose('iOS purchase result: $success');
      return success;
    } catch (e) {
      _logger.error('Error in iOS purchase: $e');
      return false;
    }
  }

  Future<void> _syncProductsWithStore(List<Product> products) async {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final storeProductIds = products
        .map((product) {
          if (isAndroid) {
            return product.googleSubscriptionId ?? product.identifier;
          } else {
            return product.identifier;
          }
        })
        .whereType<String>()
        .toSet()
        .toList();

    if (storeProductIds.isEmpty) return;

    try {
      final storeProducts =
          await EzyRevenuePlatform.instance.getProducts(storeProductIds);
      for (var product in products) {
        final productIdToMatch = isAndroid
            ? (product.googleSubscriptionId ?? product.identifier)
            : product.identifier;

        final storeProduct = storeProducts.firstWhere(
          (sp) => sp['identifier'] == productIdToMatch,
          orElse: () => {},
        );
        if (storeProduct.isNotEmpty &&
            storeProduct['priceAmountMicros'] != null) {
          product.price = Price(
            amount: storeProduct['priceAmountMicros'],
            currency: storeProduct['priceCurrencyCode'],
          );
        }
      }
    } catch (e) {
      _logger.error('Error syncing products with store: $e');
    }
  }
}

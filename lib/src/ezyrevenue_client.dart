import 'dart:io';

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
/// The SDK automatically:
/// - Authenticates the user on first launch
/// - Persists the session locally so subsequent launches skip the login call
/// - Syncs product prices with the native store (Google Play / App Store)
class EzyRevenue {
  // ── Private constructor & singleton ──────────────────────────────────

  EzyRevenue._();

  static EzyRevenue? _instance;

  /// The shared singleton instance.
  ///
  /// Throws a [StateError] if [init] has not been called yet.
  static EzyRevenue get instance {
    if (_instance == null) {
      throw StateError(
        'EzyRevenue has not been initialized. '
        'Call EzyRevenue.init() before accessing the instance.',
      );
    }
    return _instance!;
  }

  /// Whether the SDK has been initialized.
  static bool get isInitialized => _instance != null;

  // ── Internal state ──────────────────────────────────────────────────

  late final EzyRevenueConfig _config;
  late final EzyRevenueLogger _logger;
  late final EzyRevenueApi _api;
  late final EzyRevenueSessionStorage _sessionStorage;

  String? _appAccessToken;

  /// The current default offering, if available.
  Offering? currentOffering;

  /// Cached list of all offerings.
  List<Offering> _offerings = [];

  /// Read-only access to the cached offerings list.
  List<Offering> get offerings => List.unmodifiable(_offerings);

  // ── Initialization ──────────────────────────────────────────────────

  /// The current version of the SDK.
  static const String sdkVersion = '0.0.2';

  /// Initializes the EzyRevenue SDK.
  ///
  /// This method:
  /// 1. Configures the SDK with the provided [config].
  /// 2. Checks for a previously saved login session.
  /// 3. If a valid session exists for the same user, restores it (no network call).
  /// 4. Otherwise, authenticates with the backend and persists the new session.
  ///
  /// Must be called before accessing [instance]. Typically called once in
  /// `main()` before `runApp()`.
  ///
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await EzyRevenue.init(
  ///     config: EzyRevenueConfig(
  ///       apiKey: 'your_api_key',
  ///       appUserId: 'user-uuid',
  ///     ),
  ///   );
  ///   runApp(const MyApp());
  /// }
  /// ```
  ///
  /// Throws an [Exception] if login fails and no cached session is available.
  static Future<void> init({required EzyRevenueConfig config}) async {
    final sdk = EzyRevenue._();
    sdk._config = config;

    sdk._logger = EzyRevenueLogger(
      level: config.logLevel,
      onLog: config.onLog,
    );

    sdk._api = EzyRevenueApi(
      apiKey: config.apiKey,
      logger: sdk._logger,
    );

    sdk._sessionStorage = EzyRevenueSessionStorage(logger: sdk._logger);

    sdk._logger.verbose('Initializing EzyRevenue SDK v$sdkVersion');
    sdk._logger.verbose('User ID: ${config.appUserId}');

    // Try to restore a cached session for this user
    final hasSession =
        await sdk._sessionStorage.hasValidSession(config.appUserId);

    if (hasSession) {
      final session = await sdk._sessionStorage.loadSession();
      sdk._appAccessToken = session!.accessToken;
      sdk._logger.verbose('Restored cached session — skipping network login.');
    } else {
      // No cached session — perform a fresh login
      sdk._logger.verbose('No cached session found — logging in...');
      await sdk._performLogin();
    }

    if (Platform.isAndroid) {
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
      currentOffering =
          _offerings.firstWhere((offering) => offering.isDefault);
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
    return Platform.isIOS
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
    final storeProductIds = products
        .map((product) {
          if (Platform.isAndroid) {
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
        final productIdToMatch = Platform.isAndroid
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

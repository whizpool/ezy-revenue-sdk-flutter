/// Represents the API response containing a list of products.
class ProductsResponse {
  /// Whether the API call was successful.
  final bool success;

  /// The list of products returned.
  final List<Product> data;

  /// Creates a [ProductsResponse].
  ProductsResponse({required this.success, required this.data});

  /// Creates a [ProductsResponse] from a JSON map.
  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    return ProductsResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List).map((i) => Product.fromJson(i)).toList(),
    );
  }
}

/// A subscription or in-app purchase product.
class Product {
  /// Server-side product ID.
  final String? productId;

  /// Canonical identifier for this product.
  final String identifier;

  /// Human-readable display name.
  final String displayName;

  /// Product type (e.g. "subscription", "consumable").
  final String type;

  /// Store-side status (e.g. "ACTIVE", "INACTIVE").
  final String storeStatus;

  /// Optional product group identifier.
  final String? productGroup;

  /// Whether this product is currently active.
  final bool isActive;

  /// The price of this product. May be updated from store data.
  Price? price;

  /// The introductory/trial price, if any.
  final Price? introductoryPrice;

  // — Google Play fields —

  /// Google Play subscription ID.
  final String? googleSubscriptionId;

  /// Google Play base plan ID.
  final String? googleBasePlanId;

  // — Apple fields —

  /// Apple subscription group ID.
  final String? appleSubscriptionGroup;

  /// Apple subscription group display name.
  final String? appleSubscriptionGroupName;

  /// Apple subscription period (e.g. "P1M", "P1Y").
  final String? appleSubscriptionPeriod;

  /// Apple in-app purchase type.
  final String? appleInAppPurchaseType;

  /// Apple review note.
  final String? appleReviewNote;

  /// Whether the product supports Apple Family Sharing.
  final bool? appleFamilySharable;

  /// Apple schedule identifier.
  final String? appleScheduleId;

  /// Creates a [Product].
  Product({
    this.productId,
    required this.identifier,
    required this.displayName,
    required this.type,
    required this.storeStatus,
    this.productGroup,
    required this.isActive,
    this.price,
    this.introductoryPrice,
    this.googleSubscriptionId,
    this.googleBasePlanId,
    this.appleSubscriptionGroup,
    this.appleSubscriptionGroupName,
    this.appleSubscriptionPeriod,
    this.appleInAppPurchaseType,
    this.appleReviewNote,
    this.appleFamilySharable,
    this.appleScheduleId,
  });

  /// Creates a [Product] from a JSON map.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'],
      identifier: json['identifier'] ?? '',
      displayName: json['displayName'] ?? json['name'] ?? '',
      type: json['type'] ?? '',
      storeStatus: json['storeStatus'] ?? json['status'] ?? '',
      productGroup: json['productGroup'] ?? json['group'],
      isActive: json['isActive'] ?? (json['status'] == 'ACTIVE'),
      price: json['price'] != null ? Price.fromJson(json['price']) : null,
      introductoryPrice: json['introductoryPrice'] != null
          ? Price.fromJson(json['introductoryPrice'])
          : null,
      googleSubscriptionId: json['googleSubscriptionId'],
      googleBasePlanId: json['googleBasePlanId'],
      appleSubscriptionGroup: json['appleSubscriptionGroup'],
      appleSubscriptionGroupName: json['appleSubscriptionGroupName'],
      appleSubscriptionPeriod: json['appleSubscriptionPeriod'],
      appleInAppPurchaseType: json['appleInAppPurchaseType'],
      appleReviewNote: json['appleReviewNote'],
      appleFamilySharable: json['appleFamilySharable'],
      appleScheduleId: json['appleScheduleId'],
    );
  }
}

/// Represents a price with an amount in micros and a currency code.
class Price {
  /// The price amount in micros (1,000,000 micros = 1 unit of currency).
  int amount;

  /// The ISO 4217 currency code (e.g. "USD", "EUR").
  String currency;

  /// The price in standard currency units (e.g. 4.99 instead of 4990000).
  double get normalPrice => amount / 1000000;

  /// Creates a [Price].
  Price({required this.amount, required this.currency});

  /// Creates a [Price] from a JSON map.
  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      amount: json['amount'],
      currency: json['currency'],
    );
  }

  @override
  String toString() => '$normalPrice $currency';
}

/// A product as represented by the native platform store (Google Play / App Store).
class StoreProduct {
  /// The store-specific product identifier.
  final String identifier;

  /// The product title from the store.
  final String title;

  /// The product description from the store.
  final String description;

  /// The price from the store.
  final Price price;

  /// Creates a [StoreProduct].
  StoreProduct({
    required this.identifier,
    required this.title,
    required this.description,
    required this.price,
  });

  /// Creates a [StoreProduct] from a platform channel map.
  factory StoreProduct.fromMap(Map<String, dynamic> map) {
    return StoreProduct(
      identifier: map['identifier'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: Price(
        amount: map['priceAmountMicros'] ?? 0,
        currency: map['priceCurrencyCode'] ?? '',
      ),
    );
  }
}

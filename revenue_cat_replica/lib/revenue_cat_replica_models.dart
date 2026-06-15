class OfferingsResponse {
  final String? currentOfferingId;
  final List<Offering> offerings;

  OfferingsResponse({this.currentOfferingId, required this.offerings});

  factory OfferingsResponse.fromJson(Map<String, dynamic> json) {
    return OfferingsResponse(
      currentOfferingId: json['current_offering_id'],
      offerings: (json['offerings'] as List)
          .map((i) => Offering.fromJson(i))
          .toList(),
    );
  }
}

class ProductsResponse {
  final bool success;
  final List<Product> data;

  ProductsResponse({required this.success, required this.data});

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    return ProductsResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List)
          .map((i) => Product.fromJson(i))
          .toList(),
    );
  }
}

class Offering {
  final String identifier;
  final String description;
  final bool isDefault;
  final List<Package> packages;

  Offering({
    required this.identifier,
    required this.description,
    required this.isDefault,
    required this.packages,
  });

  factory Offering.fromJson(Map<String, dynamic> json) {
    return Offering(
      identifier: json['identifier'],
      description: json['description'],
      isDefault: json['isDefault'] ?? false,
      packages: (json['packages'] as List)
          .map((i) => Package.fromJson(i))
          .toList(),
    );
  }
}

class Package {
  final String identifier;
  final String platformProductIdentifier;
  final List<Product> products;

  Package({
    required this.identifier,
    required this.platformProductIdentifier,
    required this.products,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      identifier: json['identifier'],
      platformProductIdentifier: json['platform_product_identifier'],
      products: (json['products'] as List)
          .map((i) => Product.fromJson(i))
          .toList(),
    );
  }
}

class Product {
  final String? productId;
  final String identifier;
  final String displayName;
  final String type;
  final String storeStatus;
  final String? productGroup;
  final bool isActive;
  Price? price;
  final Price? introductoryPrice;
  final String? googleSubscriptionId;
  final String? googleBasePlanId;
  final String? appleSubscriptionGroup;
  final String? appleSubscriptionGroupName;
  final String? appleSubscriptionPeriod;
  final String? appleInAppPurchaseType;
  final String? appleReviewNote;
  final bool? appleFamilySharable;
  final String? appleScheduleId;

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

class Price {
  int amount;
  String currency;
  double get normalPrice => amount / 1000000;

  Price({required this.amount, required this.currency});

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      amount: json['amount'],
      currency: json['currency'],
    );
  }

  @override
  String toString() => '$normalPrice $currency';
}

class StoreProduct {
  final String identifier;
  final String title;
  final String description;
  final Price price;

  StoreProduct({
    required this.identifier,
    required this.title,
    required this.description,
    required this.price,
  });

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

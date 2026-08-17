import 'product.dart';

/// Represents the API response containing available offerings.
class OfferingsResponse {
  /// The identifier of the current/default offering.
  final String? currentOfferingId;

  /// The list of all available offerings.
  final List<Offering> offerings;

  /// Creates an [OfferingsResponse].
  OfferingsResponse({this.currentOfferingId, required this.offerings});

  /// Creates an [OfferingsResponse] from a JSON map.
  factory OfferingsResponse.fromJson(Map<String, dynamic> json) {
    return OfferingsResponse(
      currentOfferingId: json['current_offering_id'],
      offerings:
          (json['offerings'] as List).map((i) => Offering.fromJson(i)).toList(),
    );
  }
}

/// A group of [Package]s that can be presented to a user as a subscription
/// offering (e.g. "Premium", "Standard").
class Offering {
  /// Unique identifier for this offering.
  final String identifier;

  /// Human-readable description of this offering.
  final String description;

  /// Whether this is the default offering shown to users.
  final bool isDefault;

  /// The packages available within this offering.
  final List<Package> packages;

  /// Creates an [Offering].
  Offering({
    required this.identifier,
    required this.description,
    required this.isDefault,
    required this.packages,
  });

  /// Creates an [Offering] from a JSON map.
  factory Offering.fromJson(Map<String, dynamic> json) {
    return Offering(
      identifier: json['identifier'],
      description: json['description'],
      isDefault: json['isDefault'] ?? false,
      packages:
          (json['packages'] as List).map((i) => Package.fromJson(i)).toList(),
    );
  }
}

/// A single purchasable package within an [Offering].
///
/// Each package maps to one or more platform-specific products.
class Package {
  /// Unique identifier for this package (e.g. "\$rc_monthly").
  final String identifier;

  /// The platform-specific product identifier (e.g. Google Play or App Store ID).
  final String platformProductIdentifier;

  /// The products associated with this package.
  final List<Product> products;

  /// Creates a [Package].
  Package({
    required this.identifier,
    required this.platformProductIdentifier,
    required this.products,
  });

  /// Creates a [Package] from a JSON map.
  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      identifier: json['identifier'],
      platformProductIdentifier: json['platform_product_identifier'],
      products:
          (json['products'] as List).map((i) => Product.fromJson(i)).toList(),
    );
  }
}

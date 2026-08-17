# EzyRevenue Flutter SDK

A Flutter plugin for managing in-app subscriptions across iOS and Android. One API key, one initialization call — EzyRevenue handles authentication, session persistence, offerings, and purchases.

## Table of Contents

1. [Installation](#installation)
2. [Initialization](#initialization)
3. [Fetching Offerings](#fetching-offerings)
4. [Making a Purchase](#making-a-purchase)
5. [Checking Subscription Status](#checking-subscription-status)
6. [Logging Out](#logging-out)
7. [Models Overview](#models-overview)
8. [Configuration Options](#configuration-options)
9. [API Reference](#api-reference)
10. [Platform Setup](#platform-setup)
11. [License](#license)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ezyrevenue: ^0.0.4
```

Then run:

```bash
flutter pub get
```

## Initialization

You should initialize the EzyRevenue SDK as early as possible in your app's lifecycle, typically in your `main()` function before `runApp`.

Initialization requires your `apiKey` and a unique `appUserId` for the current user. The SDK will automatically handle authentication, cache the session, and seamlessly resume previous sessions on subsequent app launches.

```dart
import 'package:flutter/material.dart';
import 'package:ezyrevenue/ezyrevenue.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EzyRevenue.init(
    config: EzyRevenueConfig(
      apiKey: 'YOUR_EZYREVENUE_API_KEY',
      appUserId: 'USER_UNIQUE_ID', // e.g. a UUID, Firebase UID, or your backend's user ID
      logLevel: LogLevel.verbose, // Optional: useful for debugging
      onLog: (message) {
        // Optional: Route SDK logs to your custom logging tool
        debugPrint('EzyRevenue: $message');
      },
    ),
  );

  runApp(const MyApp());
}
```

> **Note**: `EzyRevenue.init` will cache the user session. You do not need to re-login on every app launch manually.

## Fetching Offerings

An **Offering** is a grouping of packages you want to present to a user (e.g., a "Premium" paywall with Monthly and Annual options).

To fetch the available offerings for the current user:

```dart
try {
  // Fetch offerings from the network
  List<Offering> offerings = await EzyRevenue.instance.getOfferings();

  if (offerings.isEmpty) {
    print("No offerings available.");
    return;
  }

  // You can also access the default offering if configured in your dashboard
  Offering? defaultOffering = EzyRevenue.instance.currentOffering;

  if (defaultOffering != null) {
    print("Default Offering: ${defaultOffering.description}");
    
    // Iterate over packages in the default offering
    for (Package package in defaultOffering.packages) {
      print("Package ID: ${package.identifier}");
      
      // Each package has associated products (pricing info)
      for (Product product in package.products) {
         print("Product ID: ${product.identifier}");
         print("Price: ${product.price?.toString()}"); // e.g. 4.99 USD
      }
    }
  }

} catch (e) {
  print("Failed to fetch offerings: $e");
}
```

The SDK automatically synchronizes prices with the native store (Google Play or App Store) so you will always display the correct localized price to the user.

## Making a Purchase

Once you have presented the packages to the user, you can initiate a purchase. The SDK automatically routes the purchase to the correct native flow (App Store on iOS, Google Play on Android).

### Purchasing via a Package

This is the recommended approach. Pass the user-selected `Package` to `purchasePackage()`:

```dart
// Assuming the user selected the first package of the default offering
Package selectedPackage = defaultOffering.packages.first;

try {
  bool success = await EzyRevenue.instance.purchasePackage(selectedPackage);

  if (success) {
    print("Purchase successful!");
    // You should now check the subscriber status to unlock premium content
    await checkPremiumStatus();
  } else {
    print("Purchase was cancelled or failed.");
  }
} catch (e) {
  print("An error occurred during purchase: $e");
}
```

### Purchasing via a Product ID

If you need to purchase a specific product by its raw identifier instead of a package:

```dart
bool success = await EzyRevenue.instance.purchaseProduct('your_product_identifier');
```

## Checking Subscription Status

After a successful purchase, or when your app starts, you should check the user's entitlements (what they have access to) to unlock premium features.

```dart
Future<void> checkPremiumStatus() async {
  try {
    Map<String, dynamic> subscriberData = await EzyRevenue.instance.getSubscriber();
    
    // Inspect the subscriberData map to see active entitlements
    // Structure depends on your dashboard configuration.
    // Example logic:
    if (subscriberData['entitlements']?['premium']?['is_active'] == true) {
      print("User is Premium!");
      // Unlock premium UI
    } else {
      print("User is on the Free tier.");
    }
  } catch (e) {
    print("Failed to get subscriber info: $e");
  }
}
```

## Logging Out

If your app has a login/logout system, make sure to log out from EzyRevenue as well. This clears the cached session from device storage.

```dart
await EzyRevenue.instance.logout();
```

> **Important**: After calling `logout()`, you must call `EzyRevenue.init()` again with a new `appUserId` before making any further API calls.

## Models Overview

Here is a quick reference to the main models exposed by the SDK:

### `Offering`

A grouping of packages, representing a paywall or a specific presentation of subscription tiers.

- `identifier`: Unique ID for the offering.
- `description`: Human-readable description.
- `isDefault`: Whether it's the primary offering.
- `packages`: A list of `Package` objects inside this offering.

### `Package`

A purchasable tier (e.g., "$9.99 Monthly").

- `identifier`: Unique ID for the package.
- `platformProductIdentifier`: The raw native store product ID.
- `products`: A list of `Product`s providing detailed pricing.

### `Product`

Detailed store data and pricing information for an item.

- `displayName`: Store display name.
- `type`: "subscription" or "consumable".
- `price`: A `Price` object containing the `amount` (micros), `currency`, and a helper `normalPrice` getter.

### `Price`

Contains currency and formatting logic.

- `amount`: Raw price in micros (e.g. `4990000`).
- `currency`: ISO 4217 code (e.g. `USD`).
- `normalPrice`: Double representation (e.g. `4.99`). Can be converted to string via `.toString()`.

## Configuration Options

| Parameter   | Type                | Required | Description                                  |
| ----------- | ------------------- | -------- | -------------------------------------------- |
| `apiKey`    | `String`            | ✅       | Your EzyRevenue API key from the dashboard   |
| `appUserId` | `String`            | ✅       | Unique identifier for the current user       |
| `logLevel`  | `LogLevel`          | ❌       | `none` (default), `error`, or `verbose`      |
| `onLog`     | `Function(String)?` | ❌       | Callback for SDK log messages                |

### Enable Debug Logging

```dart
await EzyRevenue.init(
  config: EzyRevenueConfig(
    apiKey: 'your_api_key',
    appUserId: 'your_user_id',
    logLevel: LogLevel.verbose,
    onLog: (msg) => debugPrint(msg),
  ),
);
```

## API Reference

| Method / Property | Returns | Description |
| ----------------- | ------- | ----------- |
| `EzyRevenue.init(config:)` | `Future<void>` | Initialize the SDK (call once) |
| `EzyRevenue.instance` | `EzyRevenue` | Access the singleton |
| `.getOfferings()` | `Future<List<Offering>>` | Fetch available offerings |
| `.getProducts()` | `Future<List<Product>>` | Fetch all products |
| `.purchasePackage(package)` | `Future<bool>` | Purchase a package |
| `.purchaseProduct(id)` | `Future<bool>` | Purchase by product ID |
| `.getSubscriber()` | `Future<Map<String, dynamic>>` | Fetch subscriber entitlements |
| `.logout()` | `Future<void>` | Clear session and reset SDK |
| `.getPlatformVersion()` | `Future<String?>` | Fetch native platform OS version |
| `.currentOffering` | `Offering?` | The default offering |
| `.offerings` | `List<Offering>` | Cached offerings list |
| `.appUserId` | `String` | The configured user ID |
| `.isAuthenticated` | `bool` | Whether a valid token exists |

## Platform Setup

### Android

No additional setup required. Make sure your app is correctly configured in the Google Play Console for billing.

### iOS

No additional setup required. Make sure your app is correctly configured in App Store Connect with the proper capabilities.

## License

See [LICENSE](LICENSE) for details.

# EzyRevenue Flutter SDK

A Flutter plugin for managing in-app subscriptions across iOS and Android. One API key, one initialization call — EzyRevenue handles authentication, session persistence, offerings, and purchases.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ezyrevenue: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:ezyrevenue/ezyrevenue.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EzyRevenue.init(
    config: EzyRevenueConfig(
      apiKey: 'your_api_key',
      appUserId: 'your_user_id',
    ),
  );

  runApp(const MyApp());
}
```

That's it. The SDK logs the user in automatically and caches the session — subsequent app launches skip the network login entirely.

## Usage

### Get Offerings

```dart
final offerings = await EzyRevenue.instance.getOfferings();

// The default offering (if one is marked as default on your dashboard)
final defaultOffering = EzyRevenue.instance.currentOffering;
```

### Purchase a Package

```dart
final package = offerings.first.packages.first;
final success = await EzyRevenue.instance.purchasePackage(package);
```

### Get Subscriber Info

```dart
final subscriber = await EzyRevenue.instance.getSubscriber();
```

### Logout

Clears the cached session. Call `EzyRevenue.init()` again to re-authenticate.

```dart
await EzyRevenue.instance.logout();
```

## Configuration Options

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `apiKey` | `String` | ✅ | Your EzyRevenue API key from the dashboard |
| `appUserId` | `String` | ✅ | Unique identifier for the current user |
| `logLevel` | `LogLevel` | ❌ | `none` (default), `error`, or `verbose` |
| `onLog` | `Function(String)?` | ❌ | Callback for SDK log messages |

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

| Method | Returns | Description |
|--------|---------|-------------|
| `EzyRevenue.init(config:)` | `Future<void>` | Initialize the SDK (call once) |
| `EzyRevenue.instance` | `EzyRevenue` | Access the singleton |
| `.getOfferings()` | `Future<List<Offering>>` | Fetch available offerings |
| `.getProducts()` | `Future<List<Product>>` | Fetch all products |
| `.purchasePackage(package)` | `Future<bool>` | Purchase a package |
| `.purchaseProduct(id)` | `Future<bool>` | Purchase by product ID |
| `.getSubscriber()` | `Future<Map>` | Fetch subscriber entitlements |
| `.logout()` | `Future<void>` | Clear session and reset SDK |
| `.currentOffering` | `Offering?` | The default offering |
| `.offerings` | `List<Offering>` | Cached offerings list |
| `.appUserId` | `String` | The configured user ID |
| `.isAuthenticated` | `bool` | Whether a valid token exists |

## Platform Setup

### Android

No additional setup required.

### iOS

No additional setup required.

## License

See [LICENSE](LICENSE) for details.

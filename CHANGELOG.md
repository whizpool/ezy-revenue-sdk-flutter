## 0.0.2

* Added Swift Package Manager (SPM) support for iOS.
* Verbose logs are now suppressed in release builds to prevent accidental token/header exposure.
* Access token is now encrypted before storing in SharedPreferences (backward-compatible with 0.0.1 sessions).
* Guarded internal method channel logging with `kDebugMode`.

## 0.0.1

* Initial release.
* Cross-platform (iOS, Android, Web) in-app subscription management.
* Single-call SDK initialization with automatic session persistence.
* Fetch offerings, packages, and products from the EzyRevenue dashboard.
* Purchase packages or individual products via native store flows.
* Query subscriber entitlements.
* Configurable logging with `LogLevel` and custom `onLog` callback.


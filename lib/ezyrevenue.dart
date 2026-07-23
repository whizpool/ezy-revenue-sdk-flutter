/// EzyRevenue Flutter SDK — In-app subscription management made easy.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:ezyrevenue/ezyrevenue.dart';
///
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
/// See the [EzyRevenue] class documentation for the full API.
library;

export 'src/ezyrevenue_client.dart' show EzyRevenue;
export 'src/ezyrevenue_config.dart' show EzyRevenueConfig, LogLevel;
export 'src/models/models.dart';

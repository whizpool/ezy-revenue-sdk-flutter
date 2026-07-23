import 'package:flutter/material.dart';
import 'package:ezyrevenue/ezyrevenue.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One-call initialization — handles login & session persistence automatically
  await EzyRevenue.init(
    config: EzyRevenueConfig(
      apiKey: 'goog_yq1f0lgstqzihbqp41ol9wvebkp1qcnlv0codk',
      appUserId: '96ebc94e-152f-4971-a263-6bbfdfabdd25',
      logLevel: LogLevel.verbose,
      onLog: (msg) => debugPrint('ExampleApp: $msg'),
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _status = 'SDK initialized ✓';
  bool _isLoading = false;

  void _setStatus(String status) {
    if (!mounted) return;
    setState(() => _status = status);
  }

  void _setLoading(bool loading) {
    if (!mounted) return;
    setState(() => _isLoading = loading);
  }

  @override
  Widget build(BuildContext context) {
    final sdk = EzyRevenue.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('EzyRevenue Example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        _status,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'User: ${sdk.appUserId}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),

              const SizedBox(height: 32),

              // Fetch Offerings
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          _setLoading(true);
                          _setStatus('Fetching offerings...');
                          try {
                            final offerings = await sdk.getOfferings();
                            if (!context.mounted) return;
                            if (offerings.isNotEmpty) {
                              _setStatus(
                                'Loaded ${offerings.length} offering(s)',
                              );
                              _showOfferingsBottomSheet(context, offerings);
                            } else {
                              _setStatus('No offerings found.');
                            }
                          } catch (e) {
                            _setStatus('Error: $e');
                          } finally {
                            _setLoading(false);
                          }
                        },
                  child: const Text('Fetch & Show Offerings'),
                ),
              ),

              const SizedBox(height: 12),

              // Get Subscriber
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          _setLoading(true);
                          _setStatus('Fetching subscriber info...');
                          try {
                            final subscriber = await sdk.getSubscriber();
                            _setStatus(
                              subscriber.isNotEmpty
                                  ? 'Subscriber loaded ✓'
                                  : 'No subscriber data.',
                            );
                          } catch (e) {
                            _setStatus('Error: $e');
                          } finally {
                            _setLoading(false);
                          }
                        },
                  child: const Text('Get Subscriber (Entitlements)'),
                ),
              ),

              const SizedBox(height: 12),

              // Logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          await sdk.logout();
                          _setStatus('Logged out. Restart app to re-init.');
                        },
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfferingsBottomSheet(
    BuildContext context,
    List<Offering> offerings,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Available Offerings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: offerings.length,
                  itemBuilder: (context, index) {
                    final offering = offerings[index];
                    return ListTile(
                      title: Text(offering.description),
                      subtitle: Text(offering.description),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _showPackagesBottomSheet(context, offering);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPackagesBottomSheet(BuildContext context, Offering offering) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Packages for ${offering.identifier}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...offering.packages.map((package) {
                return ListTile(
                  title: Text(package.identifier),
                  subtitle: Text(package.platformProductIdentifier),
                  onTap: () async {
                    Navigator.pop(bc);
                    final success = await EzyRevenue.instance.purchasePackage(
                      package,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Purchase successful!'
                                : 'Purchase cancelled or failed.',
                          ),
                        ),
                      );
                    }
                  },
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

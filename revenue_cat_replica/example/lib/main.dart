import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:revenue_cat_replica/revenue_cat_replica.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _revenueCatReplicaPlugin = RevenueCatReplica();

  @override
  void initState() {
    super.initState();
    // _revenueCatReplicaPlugin.configure("goog_2rukr7yydmucvjld13us2xxakkb37qvtzhtrfs");
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _revenueCatReplicaPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('RevenueCat Replica Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Running on: $_platformVersion\n'),
              ElevatedButton(
                onPressed: () {
                  _revenueCatReplicaPlugin.showToast("Hello from RevenueCat Replica!");
                },
                child: const Text('Show Toast'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _revenueCatReplicaPlugin.login("7cf1428c-236b-4dd5-ad32-909f4f25d1fc");
                  } catch (e) {
                    _revenueCatReplicaPlugin.showToast("Login Error: $e");
                  }
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final offerings = await _revenueCatReplicaPlugin.getOfferings();
                    if (offerings.isNotEmpty) {
                      _showOfferingsBottomSheet(context, offerings);
                    } else {
                      _revenueCatReplicaPlugin.showToast("No offerings found.");
                    }
                  } catch (e) {
                    print("GetOfferings Error: $e");
                  }
                },
                child: const Text('Fetch & Show Offerings'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _revenueCatReplicaPlugin.getSubscriber();
                  } catch (e) {
                    print("GetSubscriber Error: $e");
                  }
                },
                child: const Text('Get Subscriber (Entitlements)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfferingsBottomSheet(BuildContext context, List<Offering> offerings) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Available Offerings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: offerings.length,
                  itemBuilder: (context, index) {
                    final offering = offerings[index];
                    return ListTile(
                      title: Text(offering.identifier),
                      subtitle: Text(offering.description),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _showPackagesBottomSheet(bc, offering);
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
                child: Text('Packages for ${offering.identifier}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...offering.packages.map((package) {
                return ListTile(
                  title: Text(package.identifier),
                  subtitle: Text(package.platformProductIdentifier),
                  onTap: () async {
                    Navigator.pop(bc);
                    await _revenueCatReplicaPlugin.purchasePackage(package);
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

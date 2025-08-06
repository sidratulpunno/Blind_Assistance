import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import 'home_screen.dart';
import 'vision_detector_views/object_detector_view.dart';
import 'package:google_ml_kit_example/tts_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ✅ STEP 1: Create a GlobalKey for our Navigator.
// This key allows us to control navigation from outside the widget tree.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  TTSService ttsService = TTSService();
  String welcomeMessage = "Welcome. The app is ready.";
  await ttsService.speak(welcomeMessage);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // Start listening as soon as the app starts.
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    // Perform an initial check to set the correct starting screen.
    _checkInitialConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    var result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  // ✅ STEP 2: This is now the ONLY place that handles connectivity-based navigation.
  void _updateConnectionStatus(List<ConnectivityResult> result) {
    // Get the navigator's current state using our global key.
    final navigator = navigatorKey.currentState;
    if (navigator == null) return; // Exit if navigator is not ready.

    // Get the name of the current route.
    String? currentRoute;
    navigator.popUntil((route) {
      currentRoute = route.settings.name;
      return true; // This doesn't actually pop anything, just gets the name.
    });

    final bool isOffline = result.contains(ConnectivityResult.none);

    if (isOffline && currentRoute != '/objectDetector') {
      // If we are offline and NOT on the detector view, go there.
      navigator.pushReplacementNamed('/objectDetector');
    } else if (!isOffline && currentRoute != '/home') {
      // If we are online and NOT on the home view, go there.
      navigator.pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ✅ STEP 3: Assign the key to the MaterialApp.
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      // We set a loading screen as the initial home, because our listener
      // will immediately navigate to the correct screen.
      home: const Scaffold(body: Center(child: CircularProgressIndicator())),

      // Define the routes that our listener will use for navigation.
      routes: {
        '/home': (context) => HomeScreen(),
        '/objectDetector': (context) => ObjectDetectorView(),
      },
    );
  }
}

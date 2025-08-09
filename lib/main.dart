import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_ml_kit_example/tts_service.dart';

import 'home_screen.dart';
import 'vision_detector_views/object_detector_view.dart';

// ✅ Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ✅ Global variables for connectivity state
bool isOfflineGlobal = false;
String? currentRouteGlobal;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Initial welcome message
  TTSService ttsService = TTSService();
  String welcomeMessage = "App is ready";
  await ttsService.speak(welcomeMessage);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // TTS Service
  late final TTSService _ttsService;

  @override
  void initState() {
    super.initState();
    _ttsService = TTSService();

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _checkInitialConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    var result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    // Update global current route
    navigator.popUntil((route) {
      currentRouteGlobal = route.settings.name;
      return true;
    });

    // Update global offline status
    isOfflineGlobal = result.contains(ConnectivityResult.none);

    // Navigation logic
    if (isOfflineGlobal && currentRouteGlobal != '/objectDetector') {
      _ttsService.speak("you are in offline mode");
      navigator.pushReplacementNamed('/objectDetector');
    } else if (!isOfflineGlobal && currentRouteGlobal != '/home') {
      navigator.pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      routes: {
        '/home': (context) => HomeScreen(),
        '/objectDetector': (context) => ObjectDetectorView(),
      },
    );
  }
}

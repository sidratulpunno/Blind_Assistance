import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import 'home_screen.dart';
import 'vision_detector_views/object_detector_view.dart';
import 'package:google_ml_kit_example/tts_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // This initial welcome message is still useful for when the app first boots up.
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

  // ✅ STEP 1: Add a TTSService instance to the state.
  late final TTSService _ttsService;

  @override
  void initState() {
    super.initState();
    // ✅ STEP 2: Initialize the TTS service.
    _ttsService = TTSService();

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _checkInitialConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _ttsService.stop(); // Good practice to stop TTS on dispose
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    var result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    String? currentRoute;
    navigator.popUntil((route) {
      currentRoute = route.settings.name;
      return true;
    });

    final bool isOffline = result.contains(ConnectivityResult.none);

    // ✅ STEP 3: Add the TTS calls before navigating.
    if (isOffline && currentRoute != '/objectDetector') {
      // Announce the switch to offline mode.
      _ttsService.speak("you are in offline mode");
      navigator.pushReplacementNamed('/objectDetector');
    } else if (!isOffline && currentRoute != '/home') {
      // Announce the switch to online mode with instructions.
      _ttsService.speak(
          "you are online. please Press the button and say 'give direction', 'describe', or 'offline direction'.");
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

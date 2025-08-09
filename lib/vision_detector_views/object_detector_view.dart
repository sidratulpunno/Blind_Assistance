// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
// import 'package:flutter_tts/flutter_tts.dart';
//
// import 'detector_view.dart';
// import 'painters/object_detector_painter.dart';
// import 'utils.dart';
// import 'package:vibration/vibration.dart';
//
// class ObjectDetectorView extends StatefulWidget {
//   @override
//   State<ObjectDetectorView> createState() => _ObjectDetectorView();
// }
//
// class _ObjectDetectorView extends State<ObjectDetectorView> {
//   ObjectDetector? _objectDetector;
//   DetectionMode _mode = DetectionMode.stream;
//   bool _canProcess = false;
//   bool _isBusy = false;
//   bool _isWarningActive = false; // Tracks if a warning is in progress
//   CustomPaint? _customPaint;
//   String? _text;
//   var _cameraLensDirection = CameraLensDirection.back;
//   int _option = 1;
//   final FlutterTts _tts = FlutterTts();
//   final _options = {
//     'default': '',
//     'object_custom': 'object_labeler.tflite',
//     'fruits': 'object_labeler_fruits.tflite',
//     'flowers': 'object_labeler_flowers.tflite',
//     'birds': 'lite-model_aiy_vision_classifier_birds_V1_3.tflite',
//     'food': 'lite-model_aiy_vision_classifier_food_V1_1.tflite',
//     'plants': 'lite-model_aiy_vision_classifier_plants_V1_3.tflite',
//     'mushrooms': 'lite-model_models_mushroom-identification_v1_1.tflite',
//     'landmarks':
//         'lite-model_on_device_vision_classifier_landmarks_classifier_north_america_V1_1.tflite',
//   };
//
//   @override
//   void dispose() {
//     _canProcess = false;
//     _objectDetector?.close();
//     _tts.stop();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(children: [
//         DetectorView(
//           title: 'Object Detector',
//           customPaint: _customPaint,
//           text: _text,
//           onImage: _processImage,
//           initialCameraLensDirection: _cameraLensDirection,
//           onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
//           onCameraFeedReady: _initializeDetector,
//           initialDetectionMode: DetectorViewMode.values[_mode.index],
//           onDetectorViewModeChanged: _onScreenModeChanged,
//         ),
//         Positioned(
//             top: 30,
//             left: 100,
//             right: 100,
//             child: Row(
//               children: [
//                 Spacer(),
//                 Container(
//                     decoration: BoxDecoration(
//                       color: Colors.black54,
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(4.0),
//                     )),
//                 Spacer(),
//               ],
//             )),
//       ]),
//     );
//   }
//
//   void _onScreenModeChanged(DetectorViewMode mode) {
//     switch (mode) {
//       case DetectorViewMode.gallery:
//         _mode = DetectionMode.single;
//         _initializeDetector();
//         return;
//
//       case DetectorViewMode.liveFeed:
//         _mode = DetectionMode.stream;
//         _initializeDetector();
//         return;
//     }
//   }
//
//   void _initializeDetector() async {
//     _objectDetector?.close();
//     _objectDetector = null;
//     print('Set detector in mode: $_mode');
//
//     if (_option == 0) {
//       final options = ObjectDetectorOptions(
//         mode: _mode,
//         classifyObjects: true,
//         multipleObjects: true,
//       );
//       _objectDetector = ObjectDetector(options: options);
//     } else if (_option > 0 && _option <= _options.length) {
//       final option = _options[_options.keys.toList()[_option]] ?? '';
//       final modelPath = await getAssetPath('assets/ml/$option');
//       final options = LocalObjectDetectorOptions(
//         mode: _mode,
//         modelPath: modelPath,
//         classifyObjects: true,
//         multipleObjects: true,
//       );
//       _objectDetector = ObjectDetector(options: options);
//     }
//
//     _canProcess = true;
//   }
//
//   Future<void> _triggerWarningVibration() async {
//     final hasVibrator = await Vibration.hasVibrator() ?? false;
//     if (!hasVibrator) {
//       print('⚠️ Device does not support vibration.');
//       return;
//     }
//
//     try {
//       final hasCustomSupport =
//           await Vibration.hasCustomVibrationsSupport() ?? false;
//       if (hasCustomSupport) {
//         // Strong warning vibration pattern
//         await Vibration.vibrate(pattern: [0, 1000]);
//       } else {
//         await Vibration.vibrate(duration: 1000);
//       }
//     } catch (e) {
//       print('❌ Vibration failed: $e');
//     }
//   }
//
//   Future<void> _processImage(InputImage inputImage) async {
//     if (_objectDetector == null || !_canProcess || _isBusy) return;
//     _isBusy = true;
//     setState(() {
//       _text = '';
//     });
//
//     final objects = await _objectDetector!.processImage(inputImage);
//
//     // Create a map to store distances for each object
//     Map<DetectedObject, double> objectDistances = {};
//
//     for (final object in objects) {
//       final distance =
//           _calculateDistance(object.boundingBox, inputImage.metadata!.size);
//       objectDistances[object] = distance * 3.28084;
//     }
//
// //Not to show the label we need to turn off
//     if (inputImage.metadata?.size != null &&
//         inputImage.metadata?.rotation != null) {
//       final painter = ObjectDetectorPainter(
//         objects,
//         inputImage.metadata!.size,
//         inputImage.metadata!.rotation,
//         _cameraLensDirection,
//         objectDistances: objectDistances, // Pass the distances map
//       );
//       _customPaint = CustomPaint(painter: painter);
//     }
//
//     for (final object in objects) {
//       final name =
//           object.labels.isNotEmpty ? object.labels.first.text : 'Object';
//       final distance =
//           _calculateDistance(object.boundingBox, inputImage.metadata!.size);
//       final distanceFeet = distance * 3.28084; // Convert meters to feet
//
//       if (distanceFeet < 1 && !_isWarningActive) {
//         _isWarningActive = true;
//
//         // Vibrate fully (e.g., 1000ms)
//         await _triggerWarningVibration();
//
//         await _speakWarning(
//             "Warning! $name is very close, only ${distanceFeet.toStringAsFixed(1)} feet away.");
//
//         await Future.delayed(const Duration(seconds: 2));
//         _isWarningActive = false;
//       } else if (!_isWarningActive) {
//         await _speak(
//             "Detected a $name, approximately ${distanceFeet.toStringAsFixed(1)} feet away.");
//         await Future.delayed(const Duration(seconds: 4));
//       }
//     }
//
//     _isBusy = false;
//     if (mounted) {
//       setState(() {});
//     }
//   }
//
//   double _calculateDistance(Rect boundingBox, Size imageSize) {
//     // Adjust these values based on your specific camera specifications.
//     const double focalLength =
//         1.04; // Typical smartphone camera focal length in mm
//     const double sensorHeight =
//         10.8; // Camera sensor height in mm (adjust for device)
//     const double realObjectHeight =
//         1.6; // Known object height in meters (e.g., average human)
//
//     // Calculate the object height in pixels relative to image size.
//     double objectHeightInPixels = boundingBox.height;
//     double imageHeightInPixels = imageSize.height;
//
//     // Convert focal length from mm to meters.
//     double focalLengthMeters = focalLength / 1000; // Convert mm to meters
//
//     // Compute the distance using the thin lens formula.
//     double distance =
//         (realObjectHeight * focalLengthMeters * imageHeightInPixels) /
//             (objectHeightInPixels * sensorHeight / 1000);
//
//     return distance; // Distance in meters
//   }
//
//   Future<void> _speak(String message) async {
//     await _tts.setLanguage("en-US");
//     await _tts.setPitch(1.0);
//     await _tts.speak(message);
//   }
//
//   Future<void> _speakWarning(String message) async {
//     await _tts.setLanguage("en-US");
//     await _tts.setPitch(1.2); // Slightly higher pitch for urgency
//     await _tts.speak(message);
//   }
// }

import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:vibration/vibration.dart';

import 'detector_view.dart';
import 'painters/object_detector_painter.dart';
import 'utils.dart';

class ObjectDetectorView extends StatefulWidget {
  @override
  State<ObjectDetectorView> createState() => _ObjectDetectorView();
}

class _ObjectDetectorView extends State<ObjectDetectorView> {
  ObjectDetector? _objectDetector;
  DetectionMode _mode = DetectionMode.stream;
  bool _canProcess = false;
  bool _isBusy = false;
  bool _isWarningActive = false;
  bool _heightsLoaded = false;

  CustomPaint? _customPaint;
  String? _text;

  var _cameraLensDirection = CameraLensDirection.back;
  int _option = 1;

  final FlutterTts _tts = FlutterTts();

  // CSV: label -> avg height (meters)
  final Map<String, double> _avgHeights = {};
  static const double _defaultHeightMeters = 1.6;

  // FOV defaults (vertical). Tune per device if needed.
  static const double _verticalFovDegBack = 100.0;
  static const double _verticalFovDegFront = 50.0;

  // Distance smoothing (EMA)
  final double emaAlpha = 0.35; // higher = more responsive, lower = smoother
  final Map<int, double> _filteredDistanceMById = {};

  // Warning thresholds
  final double dangerFeet = 1.5; // strong warning when nearer than this
  final double nearFeet = 3.0; // speak info callouts when nearer than this
  final Duration warningCooldown = const Duration(seconds: 3);
  final Duration infoCooldown = const Duration(seconds: 4);
  DateTime _lastWarningAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastInfoAt = DateTime.fromMillisecondsSinceEpoch(0);

  // Ignore very tiny detections (noisy)
  final double minBoxHeightFraction = 0.05; // 5% of image height

  final _options = {
    'default': '',
    'object_custom': 'object_labeler.tflite',
    'fruits': 'object_labeler_fruits.tflite',
    'flowers': 'object_labeler_flowers.tflite',
    'birds': 'lite-model_aiy_vision_classifier_birds_V1_3.tflite',
    'food': 'lite-model_aiy_vision_classifier_food_V1_1.tflite',
    'plants': 'lite-model_aiy_vision_classifier_plants_V1_3.tflite',
    'mushrooms': 'lite-model_models_mushroom-identification_v1_1.tflite',
    'landmarks':
        'lite-model_on_device_vision_classifier_landmarks_classifier_north_america_V1_1.tflite',
  };

  @override
  void initState() {
    super.initState();
    _loadAverageHeights();
    // Make TTS block until speaking finishes to avoid overlap
    _tts.awaitSpeakCompletion(true);
  }

  @override
  void dispose() {
    _canProcess = false;
    _objectDetector?.close();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        DetectorView(
          title: 'Object Detector',
          customPaint: _customPaint,
          text: _text,
          onImage: _processImage,
          initialCameraLensDirection: _cameraLensDirection,
          onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
          onCameraFeedReady: _initializeDetector,
          initialDetectionMode: DetectorViewMode.values[_mode.index],
          onDetectorViewModeChanged: _onScreenModeChanged,
        ),
        Positioned(
          top: 30,
          left: 100,
          right: 100,
          child: Row(
            children: [
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    _heightsLoaded ? '' : 'Loading heights…',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ]),
    );
  }

  void _onScreenModeChanged(DetectorViewMode mode) {
    switch (mode) {
      case DetectorViewMode.gallery:
        _mode = DetectionMode.single;
        _initializeDetector();
        return;
      case DetectorViewMode.liveFeed:
        _mode = DetectionMode.stream;
        _initializeDetector();
        return;
    }
  }

  Future<void> _loadAverageHeights() async {
    try {
      // Update this path to wherever you added the CSV as an asset.
      final csv =
          await rootBundle.loadString('assets/data/ObjectLabelWithHeights.csv');
      final lines = csv.split(RegExp(r'\r?\n'));
      for (final raw in lines) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        final parts = _splitCsvLine(line);
        if (parts.length < 2) continue;
        final label = parts[0].trim();
        final h = double.tryParse(parts[1].trim());
        if (label.isEmpty || h == null) continue;
        _avgHeights[_normalizeLabel(label)] = h;
      }
    } catch (e) {
      debugPrint('Failed to load heights CSV: $e');
    } finally {
      setState(() => _heightsLoaded = true);
    }
  }

  List<String> _splitCsvLine(String line) {
    final List<String> out = [];
    final sb = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        out.add(sb.toString());
        sb.clear();
      } else {
        sb.write(ch);
      }
    }
    out.add(sb.toString());
    return out;
  }

  String _normalizeLabel(String s) => s.trim().toLowerCase();

  double _heightForLabelMeters(String? label) {
    if (label == null || label.isEmpty) return _defaultHeightMeters;
    return _avgHeights[_normalizeLabel(label)] ?? _defaultHeightMeters;
  }

  void _initializeDetector() async {
    _objectDetector?.close();
    _objectDetector = null;
    debugPrint('Set detector in mode: $_mode');

    if (_option == 0) {
      final options = ObjectDetectorOptions(
        mode: _mode,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = ObjectDetector(options: options);
    } else if (_option > 0 && _option <= _options.length) {
      final option = _options[_options.keys.toList()[_option]] ?? '';
      final modelPath = await getAssetPath('assets/ml/$option');
      final options = LocalObjectDetectorOptions(
        mode: _mode,
        modelPath: modelPath,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = ObjectDetector(options: options);
    }
    _canProcess = true;
  }

  Future<void> _triggerWarningVibration() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) return;
    try {
      final hasCustom = await Vibration.hasCustomVibrationsSupport() ?? false;
      if (hasCustom) {
        await Vibration.vibrate(pattern: [0, 1000]);
      } else {
        await Vibration.vibrate(duration: 1000);
      }
    } catch (e) {
      debugPrint('Vibration failed: $e');
    }
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (_objectDetector == null || !_canProcess || _isBusy || !_heightsLoaded)
      return;
    if (inputImage.metadata?.size == null ||
        inputImage.metadata?.rotation == null) return;

    _isBusy = true;
    setState(() => _text = '');

    final objects = await _objectDetector!.processImage(inputImage);
    final Size imageSize = inputImage.metadata!.size;

    // Per-object distances (in FEET) for painter
    final Map<DetectedObject, double> objectDistancesFeet = {};
    double nearestFeet = double.infinity;
    String nearestLabel = 'Object';

    for (final obj in objects) {
      final label = obj.labels.isNotEmpty ? obj.labels.first.text : 'Object';

      // Skip tiny boxes (too noisy for distance)
      final boxFrac = obj.boundingBox.height / imageSize.height;
      if (boxFrac < minBoxHeightFraction) continue;

      // Use per-label height and vertical FOV to estimate distance
      final realHeightM = _heightForLabelMeters(label);
      final verticalFovDeg = _cameraLensDirection == CameraLensDirection.front
          ? _verticalFovDegFront
          : _verticalFovDegBack;

      double rawM = _distanceFromFov(
        obj.boundingBox.height,
        imageSize.height,
        realHeightM,
        verticalFovDeg,
      );

      // Smooth per object using trackingId when available
      final id = obj.trackingId ?? obj.hashCode;
      final prev = _filteredDistanceMById[id];
      final smoothedM =
          (prev == null) ? rawM : (emaAlpha * rawM + (1 - emaAlpha) * prev);
      _filteredDistanceMById[id] = smoothedM;

      final feet = smoothedM * 3.28084;
      objectDistancesFeet[obj] = feet;

      if (feet < nearestFeet) {
        nearestFeet = feet;
        nearestLabel = label;
      }
    }

    // Update overlay
    final painter = ObjectDetectorPainter(
      objects,
      imageSize,
      inputImage.metadata!.rotation,
      _cameraLensDirection,
      objectDistances: objectDistancesFeet,
    );
    _customPaint = CustomPaint(painter: painter);

    // Speech + warnings (nearest only, with cooldown)
    final now = DateTime.now();
    final canWarn = now.difference(_lastWarningAt) > warningCooldown;
    final canInfo = now.difference(_lastInfoAt) > infoCooldown;

    if (nearestFeet.isFinite) {
      if (nearestFeet <= dangerFeet && !_isWarningActive && canWarn) {
        _isWarningActive = true;
        _lastWarningAt = now;
        await _triggerWarningVibration();
        await _speakWarning(
          "Warning! $nearestLabel is very close, only ${nearestFeet.toStringAsFixed(1)} feet away.",
        );
        _isWarningActive = false;
      } else if (nearestFeet <= nearFeet && !_isWarningActive && canInfo) {
        _lastInfoAt = now;
        await _speak(
          "Detected a $nearestLabel, approximately ${nearestFeet.toStringAsFixed(1)} feet away.",
        );
      }
    }

    _isBusy = false;
    if (mounted) setState(() {});
  }

  /// Distance from vertical FOV (degrees). Uses: f(px) = (H/2) / tan(FOV/2)
  /// distance_m = (real_height_m * f_px) / object_height_px
  double _distanceFromFov(
    double objectHeightPx,
    double imageHeightPx,
    double realHeightM,
    double verticalFovDeg,
  ) {
    if (objectHeightPx <= 0 || imageHeightPx <= 0) return double.nan;
    final fPx = (imageHeightPx / 2.0) /
        math.tan((verticalFovDeg * math.pi / 180.0) / 2.0);
    final distM = (realHeightM * fPx) / objectHeightPx;
    return (distM.isFinite && distM > 0) ? distM : double.nan;
  }

  Future<void> _speak(String message) async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.speak(message);
  }

  Future<void> _speakWarning(String message) async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.2);
    await _tts.speak(message);
  }
}

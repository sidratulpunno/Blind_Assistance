import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  bool _isWarningActive = false; // Tracks if a warning is in progress
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.back;
  int _option = 1;
  final FlutterTts _tts = FlutterTts();
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
    'yolov8': 'yolov8n.tflite',
  };

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
                Spacer(),
                Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                    )),
                Spacer(),
              ],
            )),
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

  void _initializeDetector() async {
    _objectDetector?.close();
    _objectDetector = null;
    print('Set detector in mode: $_mode');

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

  Future<void> _processImage(InputImage inputImage) async {
    if (_objectDetector == null || !_canProcess || _isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });

    final objects = await _objectDetector!.processImage(inputImage);

    // Create a map to store distances for each object
    Map<DetectedObject, double> objectDistances = {};

    for (final object in objects) {
      final distance =
          _calculateDistance(object.boundingBox, inputImage.metadata!.size);
      objectDistances[object] = distance * 3.28084;
    }

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = ObjectDetectorPainter(
        objects,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
        objectDistances: objectDistances, // Pass the distances map
      );
      _customPaint = CustomPaint(painter: painter);
    }

    for (final object in objects) {
      final name =
          object.labels.isNotEmpty ? object.labels.first.text : 'Object';
      final distance =
          _calculateDistance(object.boundingBox, inputImage.metadata!.size);
      final distanceFeet = distance * 3.28084; // Convert meters to feet

      // if (distanceFeet < 0.5 && !_isWarningActive) {
      //   _isWarningActive = true;
      //   await _speakWarning(
      //       "Warning! $name is very close, only ${distanceFeet.toStringAsFixed(1)} feet away.");
      //   await Future.delayed(Duration(seconds: 2)); // Add delay for warnings
      //   _isWarningActive = false;
      // } else if (!_isWarningActive) {
      //   await _speak(
      //       "Detected a $name, approximately ${distanceFeet.toStringAsFixed(1)} feet away.");
      //   await Future.delayed(Duration(seconds: 4));
      // }
    }

    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  double _calculateDistance(Rect boundingBox, Size imageSize) {
    // Adjust these values based on your specific camera specifications.
    const double focalLength =
        1.04; // Typical smartphone camera focal length in mm
    const double sensorHeight =
        10.8; // Camera sensor height in mm (adjust for device)
    const double realObjectHeight =
        1.6; // Known object height in meters (e.g., average human)

    // Calculate the object height in pixels relative to image size.
    double objectHeightInPixels = boundingBox.height;
    double imageHeightInPixels = imageSize.height;

    // Convert focal length from mm to meters.
    double focalLengthMeters = focalLength / 1000; // Convert mm to meters

    // Compute the distance using the thin lens formula.
    double distance =
        (realObjectHeight * focalLengthMeters * imageHeightInPixels) /
            (objectHeightInPixels * sensorHeight / 1000);

    return distance; // Distance in meters
  }

  Future<void> _speak(String message) async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.speak(message);
  }

  Future<void> _speakWarning(String message) async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.2); // Slightly higher pitch for urgency
    await _tts.speak(message);
  }
}

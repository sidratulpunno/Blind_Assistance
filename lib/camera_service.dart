import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;

  Future<void> initializeCamera() async {
    // Request and check camera permission
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      _controller = CameraController(cameras.first, ResolutionPreset.low);
      await _controller!.initialize();
    } else if (status.isDenied || status.isPermanentlyDenied) {
      throw Exception("Camera permission denied.");
    }
  }

  Future<XFile> capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      initializeCamera();


    }
    final image = await _controller!.takePicture();
    return image;
  }

  void dispose() {
    _controller?.dispose();
  }
}

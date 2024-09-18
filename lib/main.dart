import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibration/vibration.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenCV Face Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final OpenCVExample _openCVExample = OpenCVExample();

  @override
  void initState() {
    super.initState();
    _openCVExample.initializeCamera();
  }

  @override
  void dispose() {
    _openCVExample.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Detection Example'),
      ),
      body: Center(
        child: Text('Camera is running. Move your face close to the screen.'),
      ),
    );
  }
}

class OpenCVExample {
  static const platform = MethodChannel('opencv_channel');

  CameraController? _controller;
  late List<CameraDescription> cameras;
  bool _isProcessing = false;

  // Initialize the camera and start preview from the front camera
  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((camera) =>
        camera.lensDirection == CameraLensDirection.front);

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    startImageStream();
  }

  // Start streaming images from the front camera for face detection
  void startImageStream() {
    _controller?.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      _isProcessing = true;

      // Convert the image to bytes (in real-world apps, optimize this for performance)
      Uint8List imageBytes = convertCameraImageToByte(image);

      try {
        final double distance = await platform.invokeMethod('detectFaceDistance', {
          'image': imageBytes,
        });

        if (distance <= 25.0) {
          // If face is closer than 25 cm, start vibrating the phone
          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate(duration: 1000);  // Vibrate for 1 second
          }
        }
      } on PlatformException catch (e) {
        print("Failed to detect face: '${e.message}'");
      }

      _isProcessing = false;
    });
  }

  // Convert the camera image to a format that can be processed by OpenCV
  Uint8List convertCameraImageToByte(CameraImage image) {
    // Convert the CameraImage to Uint8List
    // (Use appropriate conversion based on image format, e.g. YUV or RGB)
    return Uint8List.fromList(image.planes[0].bytes);
  }

  // Clean up the camera when done
  Future<void> dispose() async {
    await _controller?.dispose();
  }
}

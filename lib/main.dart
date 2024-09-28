import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  MyApp({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenCV Face Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(cameras: cameras),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  HomePage({required this.cameras});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late OpenCVExample _openCVExample;

  @override
  void initState() {
    super.initState();
    _openCVExample = OpenCVExample(widget.cameras);
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
      body: _openCVExample.isCameraInitialized
          ? Stack(
              children: [
                CameraPreview(_openCVExample.controller!),
                Center(
                  child: Text(
                    'Move your face close to the screen.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

class OpenCVExample {
  static const platform = MethodChannel('opencv_channel');

  CameraController? controller;
  final List<CameraDescription> cameras;
  bool _isProcessing = false;
  bool isCameraInitialized = false;

  OpenCVExample(this.cameras);

  Future<void> initializeCamera() async {
    final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);

    controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller!.initialize();
      isCameraInitialized = true;
      startImageStream();
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  void startImageStream() {
    controller?.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      _isProcessing = true;

      Uint8List imageBytes = convertYUV420toRGB(image);

      try {
        final double distance = await platform.invokeMethod(
          'detectFaceDistance',
          {
            'image': imageBytes,
          },
        );

        if (distance <= 25.0) {
          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate(duration: 1000);
          }
        }
      } on PlatformException catch (e) {
        print("Failed to detect face: '${e.message}'");
      }

      _isProcessing = false;
    });
  }

  Uint8List convertYUV420toRGB(CameraImage image) {
    return Uint8List.fromList(image.planes[0].bytes);
  }

  Future<void> dispose() async {
    await controller?.dispose();
  }
}

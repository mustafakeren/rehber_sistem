import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

class ModePage extends StatefulWidget {
  final String modeName;

  ModePage({required this.modeName});

  @override
  _ModePageState createState() => _ModePageState();
}

class _ModePageState extends State<ModePage> {
  CameraController? _cameraController;
  String responseText = "Waiting for server response...";
  late List<CameraDescription> _cameras;
  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera().then((_) {
      _startRealTimeCapture(); // Start capturing frames continuously
    });
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras(); // Get available cameras
      _cameraController = CameraController(
        _cameras[0], // Use the first camera
        ResolutionPreset.medium,
      );
      await _cameraController!.initialize();
      setState(() {}); // Update the UI once the camera is ready
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  void _startRealTimeCapture() {
    const duration = Duration(seconds: 1); // Capture every 1 second
    _captureTimer = Timer.periodic(duration, (timer) {
      _captureAndSendImage(); // Capture and send image at each interval
    });
  }

  Future<void> _captureAndSendImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() {
        responseText = "Camera is not ready.";
      });
      return;
    }

    try {
      // Capture the image
      final XFile image = await _cameraController!.takePicture();

      // Send the image to the backend
      await _sendImageToBackend(File(image.path));
    } catch (e) {
      setState(() {
        responseText = "Error capturing image: $e";
      });
    }
  }

  Future<void> _sendImageToBackend(File imageFile) async {
    try {
      final uri = Uri.parse("https://postman-echo.com/post");
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        setState(() {
          responseText = "Response: $responseBody";
        });
      } else {
        setState(() {
          responseText = "Error: ${response.statusCode} - ${response.reasonPhrase}";
        });
      }
    } catch (e) {
      setState(() {
        responseText = "Error sending image: $e";
      });
    }
  }

  @override
  void dispose() {
    _captureTimer?.cancel(); // Cancel the timer when the page is disposed
    _cameraController?.dispose(); // Dispose of the camera controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // Prevent back navigation
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF363D46),
        body: GestureDetector(
          onDoubleTap: () {
            _captureTimer?.cancel(); // Stop real-time capture on exit
            Navigator.pop(context); // Exit on double-tap
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _cameraController != null && _cameraController!.value.isInitialized
                    ? CameraPreview(_cameraController!) // Show the camera preview
                    : const Text(
                        "Initializing camera...",
                        style: TextStyle(color: Colors.white),
                      ),
                const SizedBox(height: 20),
                Text(
                  widget.modeName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  responseText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TalkPage extends StatefulWidget {
  const TalkPage({super.key});

  @override
  _TalkPageState createState() => _TalkPageState();
}

class _TalkPageState extends State<TalkPage> {
  CameraController? _cameraController;
  Timer? _frameTimer;
  bool _isSending = false;
  String _detectedEmotion = "Detecting...";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {});
      _startFrameCapture();
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  void _startFrameCapture() {
    _frameTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isSending) {
        _captureAndSendFrame();
      }
    });
  }

  Future<void> _captureAndSendFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      _isSending = true;
      final XFile frame = await _cameraController!.takePicture();
      await _sendFrameToBackend(File(frame.path));
    } catch (e) {
      print("Error capturing frame: $e");
    } finally {
      _isSending = false;
    }
  }

  Future<void> _sendFrameToBackend(File frame) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/analyze-gesture/'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', frame.path));
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        print("Backend response: $responseData"); // Debug log
        final decodedData = json.decode(responseData);

        // Handle both single and multiple emotions
        if (decodedData.containsKey("emotions")) {
          setState(() {
            _detectedEmotion = (decodedData["emotions"] as List).join(", ");
          });
        } else if (decodedData.containsKey("emotion")) {
          setState(() {
            _detectedEmotion = decodedData["emotion"] ?? "Unknown";
          });
        } else {
          setState(() {
            _detectedEmotion = "Unknown";
          });
        }
      } else {
        print("Failed to send frame: ${response.statusCode}");
        setState(() {
          _detectedEmotion = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      print("Error sending frame to backend: $e");
      setState(() {
        _detectedEmotion = "Error";
      });
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 106, 244),
      body: GestureDetector(
        onDoubleTap: () {
          Navigator.pop(context);
        },
        child: Stack(
          children: [
            Center(
              child:
                  _cameraController == null ||
                          !_cameraController!.value.isInitialized
                      ? const CircularProgressIndicator()
                      : CameraPreview(_cameraController!),
            ),
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Text(
                "Detected Emotion: $_detectedEmotion",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

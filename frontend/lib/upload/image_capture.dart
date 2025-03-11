import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:rehber_sistem/upload/camera_design.dart';
import 'package:rehber_sistem/upload/base_upload.dart';
import 'package:rehber_sistem/modes/notifier/detected_objects_notifier.dart';

class ImageCapture extends StatefulWidget {
  final String mode;
  final Function(Map<String, dynamic>) onResponse;

  const ImageCapture({super.key, required this.mode, required this.onResponse});

  @override
  State<ImageCapture> createState() => _ImageCaptureState();
}

class _ImageCaptureState extends State<ImageCapture> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  Timer? _timer;
  final FlutterTts flutterTts = FlutterTts();
  late final BaseUpload imageUpload;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTTS();
    imageUpload = BaseUpload(widget.mode);
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      // Select the back camera
      CameraDescription? backCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.back) {
          backCamera = camera;
          break;
        }
      }

      if (backCamera != null) {
        _cameraController = CameraController(backCamera, ResolutionPreset.medium);
        await _cameraController!.initialize();
        if (!mounted) return;
        setState(() {});

        _startTakingPictures();
      } else {
        DetectedObjectsNotifier.detectedObjects.value = ["Arka kamera bulunamadı."];
      }
    } catch (e) {
      DetectedObjectsNotifier.detectedObjects.value = ["Kamera başlatma hatası: $e"];
    }
  }

  void _initializeTTS() async {
    await flutterTts.setLanguage("tr-TR");
  }

  void _startTakingPictures() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _takePicture();
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();

      DetectedObjectsNotifier.detectedObjects.value = ["Görsel işleniyor..."];

      await _rotateAndUploadImage(File(image.path));
    } catch (e) {
      DetectedObjectsNotifier.detectedObjects.value = ["Fotoğraf çekme hatası: $e"];
    }
  }

  Future<void> _rotateAndUploadImage(File imageFile) async {
    try {
      // Load the image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      // Rotate the image 90 degrees
      img.Image rotatedImage = img.copyRotate(image!, 90);

      // Save the rotated image
      final rotatedImageFile = File(imageFile.path)
        ..writeAsBytesSync(img.encodeJpg(rotatedImage));

      await _uploadImage(rotatedImageFile);
    } catch (e) {
      DetectedObjectsNotifier.detectedObjects.value = ["Görsel döndürme hatası: $e"];
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    Map<String, dynamic> response = await imageUpload.uploadImage(imageFile);

    if (response.containsKey("error")) {
      DetectedObjectsNotifier.detectedObjects.value = [response["error"]];
    } else {
      widget.onResponse(response);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onDoubleTap: () {
          Navigator.pop(context);
        },
        child: CameraDesign(
          cameraController: _cameraController,
        ),
      ),
    );
  }
}
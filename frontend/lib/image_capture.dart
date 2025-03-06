import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_tts/flutter_tts.dart';

class ImageCapture extends StatefulWidget {
  const ImageCapture({super.key});

  @override
  State<ImageCapture> createState() => _ImageCaptureState();
}

class _ImageCaptureState extends State<ImageCapture> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  String? detectedObject;
  Timer? _timer;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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

        // Kamera başlatıldıktan sonra her saniye fotoğraf çek
        _startTakingPictures();
      } else {
        setState(() {
          detectedObject = "Arka kamera bulunamadı.";
        });
      }
    } catch (e) {
      setState(() {
        detectedObject = "Kamera başlatma hatası: $e";
      });
    }
  }

  void _startTakingPictures() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _takePicture();
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();

      setState(() {
        detectedObject = "Görsel işleniyor...";
      });

      await _rotateAndUploadImage(File(image.path));
    } catch (e) {
      setState(() {
        detectedObject = "Fotoğraf çekme hatası: $e";
      });
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
      setState(() {
        detectedObject = "Görsel döndürme hatası: $e";
      });
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/upload-image/'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      setState(() {
        if (response.statusCode == 200) {
          var jsonData = json.decode(responseData);
          detectedObject = jsonData['detected_objects']['detected_object'] ?? "Nesne tespit edilemedi.";
          _speakDetectedObject(detectedObject!);
        } else {
          detectedObject = "Hata oluştu.";
        }
      });
    } catch (e) {
      setState(() {
        detectedObject = "Görsel yükleme hatası: $e";
      });
    }
  }

  Future<void> _speakDetectedObject(String text) async {
    await flutterTts.speak(text);
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
        child: Center(
          child: _cameraController == null || !_cameraController!.value.isInitialized
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 300,
                      child: CameraPreview(_cameraController!),
                    ),
                    const SizedBox(height: 20),
                    detectedObject != null
                        ? Text(
                            "Tespit Edilen: $detectedObject",
                            style: const TextStyle(color: Colors.black, fontSize: 18),
                          )
                        : const CircularProgressIndicator(),
                  ],
                ),
        ),
      ),
    );
  }
}
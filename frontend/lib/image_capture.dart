import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:rehber_sistem/camera_design.dart';

class ImageCapture extends StatefulWidget {
  const ImageCapture({super.key});

  @override
  State<ImageCapture> createState() => _ImageCaptureState();
}

class _ImageCaptureState extends State<ImageCapture> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  List<String>? detectedObjects;
  Timer? _timer;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTTS();
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
          detectedObjects = ["Arka kamera bulunamadı."];
        });
      }
    } catch (e) {
      setState(() {
        detectedObjects = ["Kamera başlatma hatası: $e"];
      });
    }
  }

  void _initializeTTS() async {
    await flutterTts.setLanguage("tr-TR");
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
        detectedObjects = ["Görsel işleniyor..."];
      });

      await _rotateAndUploadImage(File(image.path));
    } catch (e) {
      setState(() {
        detectedObjects = ["Fotoğraf çekme hatası: $e"];
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
        detectedObjects = ["Görsel döndürme hatası: $e"];
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
          List<String> detectedObjectsList = [];

          if (jsonData['detected_objects'] is List) {
            for (var obj in jsonData['detected_objects']) {
              if (obj is Map) {
                detectedObjectsList.add(obj['detected_object']);
              } else {
                detectedObjectsList.add(obj.toString());
              }
            }
          }

          if (detectedObjectsList.isNotEmpty) {
            detectedObjects = detectedObjectsList;
            _speakDetectedObject(detectedObjectsList);
          } else {
            detectedObjects = ["Nesne tespit edilemedi."];
          }
        } else {
          detectedObjects = ["Hata oluştu."];
        }
      });
    } catch (e) {
      setState(() {
        detectedObjects = ["Görsel yükleme hatası: $e"];
      });
    }
  }

  Future<void> _speakDetectedObject(List<String> objects) async {
    String objectsToSpeak = objects.join(", ");
    await flutterTts.speak(objectsToSpeak);
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
          detectedObjects: detectedObjects,
        ),
      ),
    );
  }
}
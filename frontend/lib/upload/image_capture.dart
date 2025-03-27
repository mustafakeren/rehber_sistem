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
        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.medium,
        );
        await _cameraController!.initialize();
        if (!mounted) return;
        setState(() {});

        _startTakingPictures();
      } else {
        DetectedObjectsNotifier.detectedObjects.value = [
          "Arka kamera bulunamadı.",
        ];
      }
    } catch (e) {
      DetectedObjectsNotifier.detectedObjects.value = [
        "Kamera başlatma hatası: $e",
      ];
    }
  }

  void _initializeTTS() async {
    await flutterTts.setLanguage("tr-TR");
  }

  void _startTakingPictures() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
      DetectedObjectsNotifier.detectedObjects.value = [
        "Fotoğraf çekme hatası: $e",
      ];
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
      DetectedObjectsNotifier.detectedObjects.value = [
        "Görsel döndürme hatası: $e",
      ];
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    Map<String, dynamic> response = await imageUpload.uploadImage(imageFile);

    if (response.containsKey("error")) {
      DetectedObjectsNotifier.detectedObjects.value = [response["error"]];
    } else {
      _handleResponse(response);
    }
  }

  void _handleResponse(Map<String, dynamic> response) {
    print("Handling response: $response"); // Debug print
    if (response['detected_objects'] is List) {
      List<String> detectedObjectsList =
          (response['detected_objects'] as List<dynamic>)
              .map(
                (obj) =>
                    obj is Map
                        ? obj['detected_object'] as String
                        : obj.toString(),
              )
              .toList();

      // Count the occurrences of each object
      Map<String, int> objectCounts = {};
      for (var obj in detectedObjectsList) {
        objectCounts[obj] = (objectCounts[obj] ?? 0) + 1;
      }

      // Convert the counts to a list of strings
      List<String> countedObjects =
          objectCounts.entries
              .map(
                (entry) =>
                    "${entry.value} ${entry.key}${entry.value > 1 ? 's' : ''}",
              )
              .toList();

      // Get the image dimensions from the response
      int imageWidth = response['image_width'];
      int imageHeight = response['image_height'];

      // Detect object locations
      List<String> objectsWithLocations = _detectObjectLocations(
        response['detected_objects'],
        imageWidth,
        imageHeight,
      );

      print("Counted objects: $countedObjects"); // Debug print
      print("Objects with locations: $objectsWithLocations"); // Debug print

      DetectedObjectsNotifier.detectedObjects.value =
          countedObjects + objectsWithLocations;
    } else {
      DetectedObjectsNotifier.detectedObjects.value = [
        "Nesne tespit edilemedi.",
      ];
    }
  }

  List<String> _detectObjectLocations(
    List<dynamic> detectedObjects,
    int imageWidth,
    int imageHeight,
  ) {
    List<String> objectsWithLocations = [];

    for (var obj in detectedObjects) {
      print("Processing object: $obj"); // Debug print
      if (obj is Map && obj.containsKey('bounding_box')) {
        List<double> bbox = List<double>.from(obj['bounding_box']);

        double xCenter = (bbox[0] + bbox[2]) / 2;
        double yCenter = (bbox[1] + bbox[3]) / 2;

        double xNorm = xCenter / imageWidth;
        double yNorm = yCenter / imageHeight;

        String location = _getLocationDescription({'x': xNorm, 'y': yNorm});

        print(
          "Detected object: ${obj['detected_object']} at $location",
        ); // Debug print
        objectsWithLocations.add("${obj['detected_object']} at $location");
      } else {
        print("Object does not have location: $obj"); // Debug print
      }
    }

    return objectsWithLocations;
  }

  String _getLocationDescription(Map<String, dynamic> location) {
    double x = location['x'];
    double y = location['y'];

    if (x < 0.33) {
      if (y < 0.33) return "top-left";
      if (y > 0.66) return "bottom-left";
      return "left";
    } else if (x > 0.66) {
      if (y < 0.33) return "top-right";
      if (y > 0.66) return "bottom-right";
      return "right";
    } else {
      if (y < 0.33) return "top";
      if (y > 0.66) return "bottom";
      return "center";
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
        child: CameraDesign(cameraController: _cameraController),
      ),
    );
  }
}

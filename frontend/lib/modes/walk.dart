import 'package:flutter/material.dart';
import 'package:rehber_sistem/upload/image_capture.dart';
import 'package:camera/camera.dart';
import 'package:rehber_sistem/modes/notifier/detected_objects_notifier.dart';
import 'package:flutter_tts/flutter_tts.dart';

class WalkPage extends StatefulWidget {
  const WalkPage({super.key});

  @override
  _WalkPageState createState() => _WalkPageState();
}

class _WalkPageState extends State<WalkPage> {
  CameraController? _cameraController;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _informUser();
  }

  void _initializeTTS() async {
    await _flutterTts.setLanguage("tr-TR");
    await _flutterTts.awaitSpeakCompletion(true);
  }

  void _informUser() async {
    await _flutterTts.speak("Nesne tespiti başladı.");
  }

  void _handleResponse(Map<String, dynamic> response) {
    // Process the response for walk mode
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

      DetectedObjectsNotifier.detectedObjects.value = countedObjects;
      _speakDetectedObjects(countedObjects);
    } else {
      DetectedObjectsNotifier.detectedObjects.value = [
        "Nesne tespit edilemedi.",
      ];
      _flutterTts.speak("Nesne tespit edilemedi.");
    }
    // Handle the detected objects (e.g., update the UI, speak the objects)
    print(DetectedObjectsNotifier.detectedObjects.value);
  }

  Future<void> _speakDetectedObjects(List<String> objects) async {
    if (objects.isNotEmpty) {
      String objectsText = objects.join(", ");
      await _flutterTts.speak("Tespit edilen nesneler: $objectsText");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: GestureDetector(
        onDoubleTap: () async {
          await _flutterTts.speak("Ana sayfaya dönülüyor.");
          Navigator.pop(context);
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ImageCapture(mode: 'walk', onResponse: _handleResponse),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

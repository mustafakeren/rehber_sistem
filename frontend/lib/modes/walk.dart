import 'package:flutter/material.dart';
import 'package:rehber_sistem/upload/image_capture.dart';
import 'package:rehber_sistem/modes/notifier/detected_objects_notifier.dart';

class WalkPage extends StatefulWidget {
  const WalkPage({super.key});

  @override
  _WalkPageState createState() => _WalkPageState();
}

class _WalkPageState extends State<WalkPage> {
  void _handleResponse(Map<String, dynamic> response) {
    // Process the response for walk mode
    if (response['detected_objects'] is List) {
      DetectedObjectsNotifier.detectedObjects.value = (response['detected_objects'] as List<dynamic>)
          .map((obj) => obj is Map ? obj['detected_object'] as String : obj.toString())
          .toList();
    } else {
      DetectedObjectsNotifier.detectedObjects.value = ["Nesne tespit edilemedi."];
    }
    // Handle the detected objects (e.g., update the UI, speak the objects)
    print(DetectedObjectsNotifier.detectedObjects.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: GestureDetector(
        onDoubleTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ImageCapture(
                  mode: 'walk',
                  onResponse: _handleResponse,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
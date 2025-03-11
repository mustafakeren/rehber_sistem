import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:rehber_sistem/modes/notifier/detected_objects_notifier.dart';

class CameraDesign extends StatefulWidget {
  final CameraController? cameraController;

  const CameraDesign({
    Key? key,
    required this.cameraController,
  }) : super(key: key);

  @override
  _CameraDesignState createState() => _CameraDesignState();
}

class _CameraDesignState extends State<CameraDesign> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey, // Set the background color to grey
        child: Center(
          child: widget.cameraController == null || !widget.cameraController!.value.isInitialized
              ? const CircularProgressIndicator()
              : Column(
                  children: [
                    Expanded(
                      child: CameraPreview(widget.cameraController!),
                    ),
                    const SizedBox(height: 10), // Adjust the height to move the text higher
                    ValueListenableBuilder<List<String>>(
                      valueListenable: DetectedObjectsNotifier.detectedObjects,
                      builder: (context, detectedObjects, child) {
                        return detectedObjects.isNotEmpty
                            ? Column(
                                children: detectedObjects.map((obj) => Text(
                                  "Tespit Edilen: $obj",
                                  style: const TextStyle(color: Colors.black, fontSize: 18),
                                )).toList(),
                              )
                            : const CircularProgressIndicator();
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
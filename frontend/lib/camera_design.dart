import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraDesign extends StatelessWidget {
  final CameraController? cameraController;
  final List<String>? detectedObjects;

  const CameraDesign({
    Key? key,
    required this.cameraController,
    required this.detectedObjects,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey, // Set the background color to grey
      child: Center(
        child: cameraController == null || !cameraController!.value.isInitialized
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CameraPreview(cameraController!),
                  const SizedBox(height: 10), // Adjust the height to move the text higher
                  detectedObjects != null && detectedObjects!.isNotEmpty
                      ? Column(
                          children: detectedObjects!.map((obj) => Text(
                            "Tespit Edilen: $obj",
                            style: const TextStyle(color: Colors.black, fontSize: 18),
                          )).toList(),
                        )
                      : const CircularProgressIndicator(),
                ],
              ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:rehber_sistem/image_capture.dart';

class WalkPage extends StatelessWidget {
  const WalkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: GestureDetector(
        onDoubleTap: () {
          Navigator.pop(context);
        },
        child: const Center(
          child: ImageCapture()
        ),
      ),
    );

  }
}
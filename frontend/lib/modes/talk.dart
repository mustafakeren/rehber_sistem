import 'package:flutter/material.dart';


class TalkPage extends StatelessWidget {
  const TalkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 106, 244),
      body: GestureDetector(
        onDoubleTap: () {
          Navigator.pop(context);
        },
        child: const Center(
          child: Icon(Icons.mic, size: 60, color: Color.fromARGB(160, 0, 0, 0)),
        ),
      ),
    );
  }
}
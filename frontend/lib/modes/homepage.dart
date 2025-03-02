import 'package:flutter/material.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF363D46),
        body: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy < -10) {
              Navigator.pushNamed(context, '/talk');
            } else if (details.delta.dy > 10) {
              Navigator.pushNamed(context, '/read');
            }
          },
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 10) {
              Navigator.pushNamed(context, '/walk');
            } else if (details.delta.dx < -10) {
              Navigator.pushNamed(context, '/location');
            }
          },
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'lib/assets/logo.png',
                  width: 120,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
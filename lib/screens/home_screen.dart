import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mode_provider.dart';
import 'ModePage.dart'; // Import the ModePage

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final modeProvider = Provider.of<ModeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF363D46),
      body: GestureDetector(
        onPanUpdate: (details) {
          String newMode;
          if (details.delta.dy < 0) {
            newMode = "Konuşma";
          } else if (details.delta.dy > 0) {
            newMode = "Okuma";
          } else if (details.delta.dx > 0) {
            newMode = "Yürüme"; 
          } else if (details.delta.dx < 0) {
            newMode = "Konum"; 
          } else {
            return;
          }

          modeProvider.changeMode(newMode);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModePage(modeName: newMode),
            ),
          );
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/logo.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}




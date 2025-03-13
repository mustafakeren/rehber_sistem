import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(context) {
    final FlutterTts flutterTts = FlutterTts();

    Future<void> _speak(String text) async {
      await flutterTts.setLanguage("tr-TR");
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.speak(text);
    }

    // Hoş geldiniz mesajı ve modlara geçiş bilgisi
    Future<void> _welcomeMessage() async {
      await _speak(
        "Hoş geldiniz. Konuşma moduna geçmek için yukarı kaydırın. Okuma moduna geçmek için aşağı kaydırın. Yürüme moduna geçmek için sağa kaydırın. Lokasyon moduna geçmek için sola kaydırın.",
      );
    }

    // Uygulama açıldığında hoş geldiniz mesajını oynat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _welcomeMessage();
    });

    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF363D46),
        body: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy < -10) {
              _speak("Konuşma moduna geçiliyor.");
              Navigator.pushNamed(context, '/talk');
            } else if (details.delta.dy > 10) {
              _speak("Okuma moduna geçiliyor.");
              Navigator.pushNamed(context, '/read');
            }
          },
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 10) {
              _speak("Yürüme moduna geçiliyor.");
              Navigator.pushNamed(context, '/walk');
            } else if (details.delta.dx < -10) {
              _speak("Lokasyon moduna geçiliyor.");
              Navigator.pushNamed(context, '/location');
            }
          },
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Image.asset('lib/assets/logo.png', width: 120)],
            ),
          ),
        ),
      ),
    );
  }
}

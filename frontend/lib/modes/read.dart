import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class ReadPage extends StatefulWidget {
  const ReadPage({super.key});

  @override
  _ReadPageState createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  File? _image;
  String _extractedText = '';
  final ImagePicker _picker = ImagePicker();
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
    await _flutterTts.speak("Kamera açmak için uzun basın.");
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _flutterTts.speak("Görsel yakalandı. Metin çıkarılıyor.");
      _extractText();
    }
  }

  Future<void> _extractText() async {
    if (_image == null) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:8000/extract-text/'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', _image!.path));
    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      setState(() {
        _extractedText = data['text'];
      });
      await _flutterTts.speak("Metin çıkarıldı. Metin okunuyor.");
      _speakText();
    } else {
      setState(() {
        _extractedText = 'Metin çıkarma hatası';
      });
      await _flutterTts.speak("Metin çıkarma hatası.");
    }
  }

  Future<void> _speakText() async {
    await _flutterTts.speak(_extractedText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 28, 101, 8),
      body: GestureDetector(
        onDoubleTap: () async {
          await _flutterTts.speak("Ana sayfaya dönülüyor.");
          Navigator.pop(context);
        },
        onLongPress: () async {
          await _flutterTts.speak("Kamera açılıyor.");
          _pickImage();
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _image == null ? Text('Görsel seçilmedi.') : Image.file(_image!),
              SizedBox(height: 20),
              Text(_extractedText),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

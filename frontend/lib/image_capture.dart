import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class ImageCapture extends StatefulWidget {
  const ImageCapture({super.key});

  @override
  State<ImageCapture> createState() {
    return _ImageCaptureState();
  }
}

class _ImageCaptureState extends State<ImageCapture> {
  File? _takenImage;
  String? detectedObject;

  // Fotoğraf çekme fonksiyonu
  void _takePicture() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 600,
    );

    if (pickedImage == null) {
      return;
    }

    setState(() {
      _takenImage = File(pickedImage.path);
      detectedObject = "Görsel işleniyor...";
    });

    await _uploadImage(_takenImage!);
  }

  // Fotoğrafı FastAPI'ye gönderme fonksiyonu
  Future<void> _uploadImage(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:8000/upload-image/'), // FastAPI URL
    );

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
    ));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    setState(() {
      if (response.statusCode == 200) {
        var jsonData = json.decode(responseData);
        detectedObject = jsonData['detected_objects']['detected_object'] ??
            "Nesne tespit edilemedi.";
      } else {
        detectedObject = "Hata oluştu.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _takenImage != null
            ? Image.file(
                _takenImage!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 250,
              )
            : TextButton.icon(
                icon: const Icon(Icons.camera),
                label: const Text('Capture Image'),
                onPressed: _takePicture,
              ),
        const SizedBox(height: 20),
        detectedObject != null
            ? Text(
                "Tespit Edilen: $detectedObject",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              )
            : const SizedBox(),
      ],
    );
  }
}

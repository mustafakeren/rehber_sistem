import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WalkPage extends StatefulWidget {
  const WalkPage({super.key});

  @override
  State<WalkPage> createState() => _WalkPageState();
}

class _WalkPageState extends State<WalkPage> {
  String? responseText; 

  @override
  void initState() {
    super.initState();
    _sendImageToBackend(); 
  }

Future<void> _sendImageToBackend() async {
  try {

    final imageBytes = await rootBundle.load('lib/assets/test_image3.jpeg');
    final byteData = imageBytes.buffer.asUint8List();


    final url = Uri.parse("http://10.7.199.146:8000/upload-image/");
    final request = http.MultipartRequest('POST', url);
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      byteData,
      filename: "test_image.jpg",
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      setState(() {
        responseText = jsonResponse['detected_objects']['detected_object'].toString();
      });
    } else {
      setState(() {
        responseText = "Hata: ${response.statusCode} - ${response.reasonPhrase}";
      });
    }
  } catch (e) {
    setState(() {
      responseText = "Hata: $e";
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF363D46),
      body: GestureDetector(
        onDoubleTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: responseText == null
              ? const CircularProgressIndicator() 
              : Text(
                  responseText!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}

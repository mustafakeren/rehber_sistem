import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class BaseUpload {
  final String mode;

  BaseUpload(this.mode);

  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/upload-image/'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonData = json.decode(responseData);
        return jsonData;
      } else {
        return {"error": "Hata oluştu."};
      }
    } catch (e) {
      return {"error": "Görsel yükleme hatası: $e"};
    }
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'cloudinary_config.dart';

class CloudinaryService {
  static Future<String> uploadImage(Uint8List bytes, String filename) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);

    if (res.statusCode != 200) {
      throw Exception('Cloudinary upload failed: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }
}

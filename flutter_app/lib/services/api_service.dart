import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://192.168.1.6:5000';  // IP

  Future<Map<String, dynamic>> predict({
    required String imagePath,
    required String crop,
  }) async {
    try {
      print("🌐 API: Reading file...");
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      print("🌐 API: File size: ${bytes.length} bytes");

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict'),
      );

      request.fields['crop'] = crop;
      print("🌐 API: Crop: $crop");

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'image.jpg',
        ),
      );
      print("🌐 API: Sending request...");

      final response = await request.send();
      print("🌐 API: Response status: ${response.statusCode}");

      final responseBody = await response.stream.bytesToString();
      print("🌐 API: Response body: $responseBody");
      
      final data = json.decode(responseBody);

      if (data['status'] != 'success') {
        throw Exception('Prediction failed: ${data['error'] ?? 'Unknown error'}');
      }

      return data['prediction'];
    } catch (e) {
      print("🌐 API Error: $e");
      throw Exception('API Error: $e');
    }
  }

  Future<bool> ping() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
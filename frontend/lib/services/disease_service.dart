import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/translation_service.dart';

class DiseaseService {
  final String baseUrl = 'http://10.127.66.211:5000'; // Update with your IP
  
  Map<int, String> _diseaseNames = {};
  bool _isLoaded = false;
  
  Future<void> loadDiseases() async {
    if (_isLoaded) return;
    
    final isAmharic = TranslationService.isAmharic;
    final language = isAmharic ? 'am' : 'en';
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/diseases?lang=$language'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List diseases = data['diseases'];
        
        for (var disease in diseases) {
          _diseaseNames[disease['id']] = disease['name'];
        }
        _isLoaded = true;
        print('✅ Loaded ${_diseaseNames.length} diseases');
      }
    } catch (e) {
      print('❌ Failed to load diseases: $e');
    }
  }
  
  String getDiseaseName(int id) {
    return _diseaseNames[id] ?? 'Unknown';
  }
  
  bool get isLoaded => _isLoaded;
}

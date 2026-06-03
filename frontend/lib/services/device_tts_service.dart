import 'package:flutter_tts/flutter_tts.dart';

class DeviceTTSService {
  final FlutterTts _flutterTts = FlutterTts();
  
  Future<void> init() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }
  
  bool get isConfigured => true;
  
  Future<void> speak(String text, {String language = 'am'}) async {
    try {
      await _flutterTts.setLanguage(language == 'am' ? 'am-ET' : 'en-US');
      await _flutterTts.speak(text);
      print('✅ Speaking: $text');
    } catch (e) {
      print('❌ TTS error: $e');
    }
  }
  
  Future<void> speakResult(Map<String, dynamic> prediction, String language) async {
    final text = _formatResultText(prediction, language);
    await speak(text, language: language == 'am' ? 'am' : 'en');
  }
  
  String _formatResultText(Map<String, dynamic> prediction, String language) {
    if (language == 'am') {
      return 'የበሽታ ውጤት። '
          'በሽታ፦ ${prediction['disease']}። '
          'እምነት፦ ${prediction['confidence']} በመቶ። '
          'ህክምና፦ ${prediction['treatment']}።';
    } else {
      return 'Detection result. '
          'Disease: ${prediction['disease']}. '
          'Confidence: ${prediction['confidence']} percent. '
          'Treatment: ${prediction['treatment']}.';
    }
  }
  
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

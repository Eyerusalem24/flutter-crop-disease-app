import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'pages/auth_wrapper.dart';
import 'services/translation_service.dart';
import 'services/supabase_service.dart';
import 'services/device_tts_service.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  final supabase = SupabaseService();
  await supabase.init();
  
  // Initialize translations
  await TranslationService.init();

  // Initialize Device TTS (no API key needed)
  final deviceTTS = DeviceTTSService();
  await deviceTTS.init();
  
  // Initialize cameras
  cameras = await availableCameras();
  print('📷 Cameras found: ${cameras.length}');
  
  runApp(const CropDiseaseApp());
}

class CropDiseaseApp extends StatelessWidget {
  const CropDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TranslationService.instance,
      builder: (context, child) {
        return MaterialApp(
          title: TranslationService.translate('app_title'),
          theme: ThemeData(primaryColor: Colors.green),
          home: AuthWrapper(cameras: cameras),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

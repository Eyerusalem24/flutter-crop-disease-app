import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'pages/home_page.dart';
import 'services/translation_service.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TranslationService.init();
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
          theme: ThemeData(
            primaryColor: Colors.green,
            fontFamily: 'Roboto',
            useMaterial3: true,
          ),
          home: HomePage(cameras: cameras),  // ← Pass cameras here
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

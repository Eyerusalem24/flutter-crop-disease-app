import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      print("✅ Camera permission granted");
      return true;
    } else if (status.isDenied) {
      print("❌ Camera permission denied");
      return false;
    } else if (status.isPermanentlyDenied) {
      print("❌ Camera permission permanently denied");
      await openAppSettings();
      return false;
    }
    return false;
  }
  
  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }
}
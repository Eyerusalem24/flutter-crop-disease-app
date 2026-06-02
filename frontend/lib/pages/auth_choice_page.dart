import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'home_page.dart';
import 'login_page.dart';
import '../services/local_storage_service.dart';
import '../services/translation_service.dart';

class AuthChoicePage extends StatelessWidget {
  final List<CameraDescription> cameras;
  const AuthChoicePage({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    final isAmharic = TranslationService.isAmharic;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green[700]!, Colors.green[400]!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 15),
                      ],
                    ),
                    child: const Icon(Icons.agriculture, size: 50, color: Colors.green),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    isAmharic ? 'እንኳን ደህና መጡ' : 'Welcome',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginPage(
                              cameras: cameras,
                              isSignUp: true,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(isAmharic ? 'መለያ ፍጠር' : 'Create Account'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginPage(
                              cameras: cameras,
                              isSignUp: false,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(isAmharic ? 'ግባ' : 'Login'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      final storage = LocalStorageService();
                      await storage.setGuestMode(true);
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(cameras: cameras),
                          ),
                        );
                      }
                    },
                    child: Text(
                      isAmharic ? 'ያለ መለያ ቀጥል' : 'Continue as Guest',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

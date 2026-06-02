import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/supabase_service.dart';
import '../services/local_storage_service.dart';
import 'home_page.dart';
import 'auth_choice_page.dart';

List<CameraDescription> cameras = [];

class AuthWrapper extends StatefulWidget {
  final List<CameraDescription> cameras;
  const AuthWrapper({super.key, required this.cameras});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final hasChoice = await LocalStorageService().hasUserChoice();
    if (hasChoice) {
      final isGuest = await LocalStorageService().isGuestMode();
      if (!isGuest && SupabaseService().isLoggedIn) {
        // User is logged in
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    return FutureBuilder<bool>(
      future: LocalStorageService().hasUserChoice(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData && snapshot.data == true) {
          return FutureBuilder<bool>(
            future: LocalStorageService().isGuestMode(),
            builder: (context, guestSnapshot) {
              if (guestSnapshot.hasData && guestSnapshot.data == true) {
                return HomePage(cameras: widget.cameras);
              }
              if (SupabaseService().isLoggedIn) {
                return HomePage(cameras: widget.cameras);
              }
              return AuthChoicePage(cameras: widget.cameras);
            },
          );
        }
        
        return AuthChoicePage(cameras: widget.cameras);
      },
    );
  }
}

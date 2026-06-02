import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    // REPLACE WITH YOUR ACTUAL CREDENTIALS
    await Supabase.initialize(
      url: 'https://qrmhgwnnhifyztanxjtz.supabase.co',  // ← YOUR URL
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFybWhnd25uaGlmeXp0YW54anR6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzMTQ5ODcsImV4cCI6MjA5NTg5MDk4N30.1tGAb7QxhKCaYIAAE4Kq75M2d_ZZ0mkTl9LoA8-VZT0',                // ← YOUR ANON KEY
    );
    
    _initialized = true;
    print('✅ Supabase initialized');
  }

  bool get isLoggedIn {
    if (!_initialized) return false;
    return Supabase.instance.client.auth.currentSession != null;
  }

  String get userId {
    if (!_initialized || !isLoggedIn) return '';
    return Supabase.instance.client.auth.currentUser!.id;
  }

  Future<bool> signUp(String email, String password, String name) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      if (response.user != null) {
        print('✅ User registered: $email');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Sign up error: $e');
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        print('✅ User signed in: $email');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Sign in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    print('✅ User signed out');
  }

  // Save prediction to cloud
  Future<void> savePrediction(Map<String, dynamic> prediction) async {
    if (!isLoggedIn) {
      print('⚠️ Not logged in, skipping cloud save');
      return;
    }

    try {
      await Supabase.instance.client.from('predictions').insert({
        'user_id': userId,
        'crop': prediction['crop'],
        'disease': prediction['disease'],
        'confidence': prediction['confidence'],
        'treatment': prediction['treatment'],
        'image_path': prediction['imagePath'],
        'timestamp': prediction['timestamp'],
        'created_at': DateTime.now().toIso8601String(),
      });
      print('✅ Prediction saved to cloud');
    } catch (e) {
      print('❌ Cloud save error: $e');
    }
  }

  // Load predictions from cloud
  Future<List<Map<String, dynamic>>> loadPredictions() async {
    if (!isLoggedIn) return [];

    try {
      final response = await Supabase.instance.client
          .from('predictions')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);
      
      print('✅ Loaded ${response.length} predictions from cloud');
      return response.map((item) => {
        'crop': item['crop'],
        'disease': item['disease'],
        'confidence': (item['confidence'] as num).toDouble(),
        'treatment': item['treatment'],
        'imagePath': item['image_path'],
        'timestamp': item['timestamp'],
        'isFromCloud': true,
      }).toList();
    } catch (e) {
      print('❌ Load cloud error: $e');
      return [];
    }
  }
}

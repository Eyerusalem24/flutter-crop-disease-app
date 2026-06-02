import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/supabase_service.dart';
import '../services/local_storage_service.dart';
import '../services/history_service.dart';
import '../services/translation_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isSignUp;
  const LoginPage({super.key, required this.cameras, this.isSignUp = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final SupabaseService _supabase = SupabaseService();
  final LocalStorageService _storage = LocalStorageService();
  final HistoryService _historyService = HistoryService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool get _isSignUp => widget.isSignUp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    bool success;
    if (_isSignUp) {
      success = await _supabase.signUp(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );
    } else {
      success = await _supabase.signIn(
        _emailController.text,
        _passwordController.text,
      );
    }
    
    if (success && mounted) {
      await _storage.clearGuestMode();
      // Sync local predictions to cloud
      await _historyService.syncToCloud();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(cameras: widget.cameras),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSignUp ? 'Registration failed' : 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() => _isLoading = false);
  }

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.agriculture,
                          size: 50,
                          color: Colors.green[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSignUp 
                              ? (isAmharic ? 'መለያ ፍጠር' : 'Create Account')
                              : (isAmharic ? 'ግባ' : 'Login'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        if (_isSignUp)
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: isAmharic ? 'ስም' : 'Full Name',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (_isSignUp && (value == null || value.isEmpty)) {
                                return isAmharic ? 'እባክዎ ስም ያስገቡ' : 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                        
                        if (_isSignUp) const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: isAmharic ? 'የይለፍ ቃል' : 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    _isSignUp 
                                        ? (isAmharic ? 'ተመዝገብ' : 'Sign Up')
                                        : (isAmharic ? 'ግባ' : 'Login'),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginPage(
                                  cameras: widget.cameras,
                                  isSignUp: !_isSignUp,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            _isSignUp
                                ? (isAmharic ? 'አካውንት አለህ? ግባ' : 'Already have an account? Login')
                                : (isAmharic ? 'መለያ የለም? ተመዝገብ' : "Don't have an account? Sign Up"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

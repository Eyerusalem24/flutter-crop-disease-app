import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  final CameraDescription camera;
  late CameraController _controller;

  CameraService(this.camera);

  Future<void> initialize() async {
    // Try different resolution settings
    ResolutionPreset preset = ResolutionPreset.medium;
    
    // For some phones, low resolution works better
    _controller = CameraController(
      camera,
      preset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    
    try {
      await _controller.initialize();
      
      // Try to set auto focus
      if (_controller.value.isInitialized) {
        await _controller.setFocusMode(FocusMode.auto);
        await _controller.setExposureMode(ExposureMode.auto);
      }
    } catch (e) {
      print("Camera initialization error: $e");
      rethrow;
    }
  }

  bool get isInitialized => _controller.value.isInitialized;

  CameraController get controller => _controller;

  Future<String> captureImage() async {
    if (!_controller.value.isInitialized) {
      throw Exception("Camera not initialized");
    }
    
    try {
      final XFile picture = await _controller.takePicture();
      return picture.path;
    } catch (e) {
      throw Exception("Failed to capture image: $e");
    }
  }

  void dispose() {
    _controller.dispose();
  }
}
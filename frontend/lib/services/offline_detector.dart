import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class OfflineDetector {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  static final OfflineDetector _instance = OfflineDetector._internal();
  factory OfflineDetector() => _instance;
  OfflineDetector._internal();

  Future<void> loadModel() async {
    if (_isLoaded) return;
    
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      final labelsText = await rootBundle.loadString('assets/models/classes.txt');
       print(_interpreter!.getInputTensor(0).shape);
      _labels = labelsText.trim().split('\n');
      _isLoaded = true;
      print('✅ Offline detector loaded: $_labels');
    } catch (e) {
      print('❌ Failed to load offline model: $e');
      _isLoaded = false;
    }
  }

  Future<Map<String, dynamic>> predict(String imagePath) async {
  if (!_isLoaded) await loadModel();

  final bytes = await File(imagePath).readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) throw Exception('Decode failed');

  final resized = img.copyResize(image, width: 224, height: 224);

  var input = Float32List(1 * 224 * 224 * 3);
int index = 0;

for (int y = 0; y < 224; y++) {
  for (int x = 0; x < 224; x++) {
    final pixel = resized.getPixel(x, y);

    input[index++] = pixel.r / 255.0;
    input[index++] = pixel.g / 255.0;
    input[index++] = pixel.b / 255.0;
  }
}

  var output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

  _interpreter!.run(input.buffer, output);

  double maxConfidence = 0;
  int predictedIndex = 0;

  for (int i = 0; i < _labels.length; i++) {
    if (output[0][i] > maxConfidence) {
      maxConfidence = output[0][i];
      predictedIndex = i;
    }
  }

  return {
    'disease': _labels[predictedIndex],
    'confidence': (maxConfidence * 100).toStringAsFixed(1),
  };
}
  
  void dispose() {
    _interpreter?.close();
  }
}

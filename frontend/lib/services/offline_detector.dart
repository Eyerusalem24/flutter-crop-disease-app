import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

class OfflineDetector {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  static const double _meanR = 0.485;
  static const double _meanG = 0.456;
  static const double _meanB = 0.406;
  static const double _stdR = 0.229;
  static const double _stdG = 0.224;
  static const double _stdB = 0.225;

  static final OfflineDetector _instance = OfflineDetector._internal();
  factory OfflineDetector() => _instance;
  OfflineDetector._internal();

  List<double> _softmax(List<double> logits) {
    double maxLogit = logits.reduce(max);
    List<double> expValues = [];
    double sum = 0.0;
    
    for (double logit in logits) {
      double expVal = exp(logit - maxLogit);
      expValues.add(expVal);
      sum += expVal;
    }
    
    return expValues.map((val) => val / sum).toList();
  }

  Future<void> loadModel() async {
    if (_isLoaded) return;
    
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      final labelsText = await rootBundle.loadString('assets/models/classes.txt');
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
    int idx = 0;

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        
        double r = (pixel.r / 255.0 - _meanR) / _stdR;
        double g = (pixel.g / 255.0 - _meanG) / _stdG;
        double b = (pixel.b / 255.0 - _meanB) / _stdB;
        
        input[idx++] = r;
        input[idx++] = g;
        input[idx++] = b;
      }
    }

    var output = List.generate(1, (_) => List.filled(_labels.length, 0.0));
    _interpreter!.run(input.buffer, output);

    List<double> logits = output[0].cast<double>();
    List<double> probabilities = _softmax(logits);

    // Get all probabilities
    int healthyIdx = _labels.indexOf('Healthy');
    int blightIdx = _labels.indexOf('Blight');
    
    double healthyProb = healthyIdx != -1 ? probabilities[healthyIdx] * 100 : 0;
    double blightProb = blightIdx != -1 ? probabilities[blightIdx] * 100 : 0;
    
    print('📊 Healthy: ${healthyProb.toStringAsFixed(1)}%');
    print('📊 Blight: ${blightProb.toStringAsFixed(1)}%');

    String predictedClass;
    double confidencePercent;

    // Adaptive threshold - if Healthy and Blight are close, it's ambiguous
    if (healthyProb > 20 && (blightProb - healthyProb).abs() < 40) {
      predictedClass = '⚠️ Ambiguous - Please retake photo';
      confidencePercent = max(healthyProb, blightProb);
      print('📋 Ambiguous: Healthy(${healthyProb.toStringAsFixed(1)}%) vs Blight(${blightProb.toStringAsFixed(1)}%)');
    }
    else if (healthyProb > 30) {
      predictedClass = 'Healthy';
      confidencePercent = healthyProb;
      print('📋 Healthy leaf detected');
    }
    else if (blightProb > 70 && healthyProb < 20) {
      predictedClass = 'Blight';
      confidencePercent = blightProb;
      print('📋 Blight detected');
    }
    else {
      // Normal prediction
      int predictedIndex = 0;
      double maxProbability = 0;
      for (int i = 0; i < _labels.length; i++) {
        if (probabilities[i] > maxProbability) {
          maxProbability = probabilities[i];
          predictedIndex = i;
        }
      }
      predictedClass = _labels[predictedIndex];
      confidencePercent = maxProbability * 100;
    }

    confidencePercent = confidencePercent.clamp(0, 100);

    print('📊 Final: $predictedClass with ${confidencePercent.toStringAsFixed(1)}%');

    return {
      'disease': predictedClass,
      'confidence': confidencePercent.toStringAsFixed(1),
    };
  }
  
  void dispose() {
    _interpreter?.close();
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class EdgeAIService {
  static Interpreter? _interpreter;
  static bool _isLoaded = false;

  static const int _inputSize = 224;
  static const int _channels = 3;

  static final List<String> _diseaseClasses = [
    'Healthy',
    'Common Rust',
    'Gray Leaf Spot',
    'Northern Leaf Blight',
    'Late Blight',
    'Early Blight',
    'Stripe Rust',
    'Leaf Rust',
    'Blast',
    // Add all your model's classes in correct order here
  ];

  static bool get isLoaded => _isLoaded;

  static Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/crop_disease_model.tflite',
        options: InterpreterOptions()
          ..threads = 4
          ..useNnApiForAndroid = true,
      );

      print("✅ Model loaded successfully!");
      print("Input shape: ${_interpreter!.getInputTensors()[0].shape}");
      print("Output shape: ${_interpreter!.getOutputTensors()[0].shape}");

      _isLoaded = true;
    } catch (e) {
      print("❌ Failed to load model: $e");
      _isLoaded = false;
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> predictFromImage(String imagePath) async {
    if (!_isLoaded || _interpreter == null) {
      throw Exception("Model not loaded. Call loadModel() first.");
    }

    try {
      final input = await _preprocessImage(imagePath);

      final outputTensor = _interpreter!.getOutputTensors()[0];
      final outputShape = outputTensor.shape;
      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
          .reshape([outputShape[0], outputShape[1]]);

      _interpreter!.run(input, output);

      final predictions = output[0] as List<double>;
      final int predictedIndex = _argMax(predictions);
      final double confidence = predictions[predictedIndex] * 100;

      return {
        'disease': _diseaseClasses[predictedIndex],
        'confidence': confidence.toStringAsFixed(1),
        'isHealthy': predictedIndex == 0,
        'allPredictions': Map.fromIterables(_diseaseClasses, predictions),
      };
    } catch (e) {
      print("❌ Prediction error: $e");
      rethrow;
    }
  }

  static Future<List<List<List<List<double>>>>> _preprocessImage(String imagePath) async {
    final File file = File(imagePath);
    final Uint8List bytes = await file.readAsBytes();

    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception("Failed to decode image");

    img.Image resized = img.copyResize(image, width: _inputSize, height: _inputSize);

    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,   // Red
              pixel.g / 255.0,   // Green
              pixel.b / 255.0,   // Blue
            ];
          },
        ),
      ),
    );

    return input;
  }

  static int _argMax(List<double> list) {
    int maxIndex = 0;
    double maxValue = list[0];
    for (int i = 1; i < list.length; i++) {
      if (list[i] > maxValue) {
        maxValue = list[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
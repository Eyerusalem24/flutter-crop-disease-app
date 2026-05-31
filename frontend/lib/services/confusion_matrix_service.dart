import 'dart:convert';
import 'package:flutter/services.dart';
import 'history_service.dart';

class ConfusionMatrixService {
  final HistoryService _historyService = HistoryService();

  Future<List<Map<String, dynamic>>> getAllPredictions() async {
    return await _historyService.getPredictions(limit: 1000);
  }

  Future<Map<String, dynamic>> calculateMetrics() async {
    final predictions = await getAllPredictions();
    
    if (predictions.isEmpty) {
      return {
        'hasData': false,
        'totalSamples': 0,
        'accuracy': 'N/A',
        'avgPrecision': 'N/A',
        'avgRecall': 'N/A',
        'avgF1': 'N/A',
        'message': 'No predictions yet. Make some predictions first!',
      };
    }
    
    // For now, show simple stats without real accuracy calculation
    return {
      'hasData': true,
      'totalSamples': predictions.length,
      'accuracy': 'N/A',
      'avgPrecision': 'N/A',
      'avgRecall': 'N/A',
      'avgF1': 'N/A',
      'message': 'Accuracy calculation requires labeled test data. You have made ${predictions.length} prediction(s).',
    };
  }
  
  Map<String, dynamic> getModelPerformance() {
    return {
      'overallAccuracy': 'N/A',
      'loss': 'N/A',
      'trainingEpochs': 50,
    };
  }
}

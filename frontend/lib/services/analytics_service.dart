import 'package:sqflite/sqflite.dart';
import 'history_service.dart';
import 'disease_service.dart';

class AnalyticsService {
  final HistoryService _historyService = HistoryService();
  final DiseaseService _diseaseService = DiseaseService();
  
  Future<Map<String, int>> getDiseaseFrequency() async {
    await _diseaseService.loadDiseases();
    
    final predictions = await _historyService.getPredictions(limit: 1000);
    final Map<String, int> frequency = {};
    
    for (var p in predictions) {
      String diseaseName;
      
      // If we have disease_id, use it to get canonical name
      if (p.containsKey('disease_id') && p['disease_id'] != null) {
        final diseaseId = p['disease_id'] as int;
        diseaseName = _diseaseService.getDiseaseName(diseaseId);
      } else {
        // Fallback for old data
        diseaseName = p['disease'] ?? 'Unknown';
      }
      
      frequency[diseaseName] = (frequency[diseaseName] ?? 0) + 1;
    }
    
    return frequency;
  }
  
  // Rest of the methods remain the same
  Future<Map<String, int>> getCropDistribution() async {
    final predictions = await _historyService.getPredictions(limit: 1000);
    final Map<String, int> distribution = {};
    
    for (var p in predictions) {
      String crop = p['crop'] ?? 'Unknown';
      distribution[crop] = (distribution[crop] ?? 0) + 1;
    }
    
    return distribution;
  }
  
  Future<Map<String, Map<String, int>>> getDiseaseTrends() async {
    await _diseaseService.loadDiseases();
    
    final predictions = await _historyService.getPredictions(limit: 1000);
    final Map<String, Map<String, int>> trends = {};
    
    final now = DateTime.now();
    final List<String> last7Days = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      last7Days.add(_formatDateKey(date));
    }
    
    for (var day in last7Days) {
      trends[day] = {};
    }
    
    for (var p in predictions) {
      String timestamp = p['timestamp'] ?? '';
      String diseaseKey;
      
      if (p.containsKey('disease_id') && p['disease_id'] != null) {
        final diseaseId = p['disease_id'] as int;
        diseaseKey = _diseaseService.getDiseaseName(diseaseId);
      } else {
        diseaseKey = p['disease'] ?? 'Unknown';
      }
      
      String dateKey = _getDateKeyFromTimestamp(timestamp);
      
      if (trends.containsKey(dateKey)) {
        trends[dateKey]![diseaseKey] = (trends[dateKey]![diseaseKey] ?? 0) + 1;
      }
    }
    
    return trends;
  }
  
  Future<Map<String, dynamic>> getSummaryStats() async {
    final predictions = await _historyService.getPredictions(limit: 1000);
    
    int total = predictions.length;
    double avgConfidence = 0;
    int healthyCount = 0;
    int diseasedCount = 0;
    
    for (var p in predictions) {
      double conf = (p['confidence'] as num?)?.toDouble() ?? 0;
      avgConfidence += conf;
      
      String disease = p['disease'] ?? '';
      if (disease.toLowerCase().contains('healthy')) {
        healthyCount++;
      } else {
        diseasedCount++;
      }
    }
    
    avgConfidence = total > 0 ? avgConfidence / total : 0;
    
    return {
      'total': total,
      'avgConfidence': avgConfidence.toStringAsFixed(1),
      'healthyCount': healthyCount,
      'diseasedCount': diseasedCount,
    };
  }
  
  Future<MapEntry<String, int>?> getMostCommonDisease() async {
    final frequency = await getDiseaseFrequency();
    if (frequency.isEmpty) return null;
    return frequency.entries.reduce((a, b) => a.value > b.value ? a : b);
  }
  
  String _formatDateKey(DateTime date) {
    return '${date.month}/${date.day}';
  }
  
  String _getDateKeyFromTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return _formatDateKey(date);
    } catch (e) {
      return _formatDateKey(DateTime.now());
    }
  }
}

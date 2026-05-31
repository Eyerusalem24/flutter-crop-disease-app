import 'package:sqflite/sqflite.dart';
import 'history_service.dart';

class AnalyticsService {
  final HistoryService _historyService = HistoryService();

  // Get all predictions for analysis
  Future<List<Map<String, dynamic>>> getAllPredictions() async {
    return await _historyService.getPredictions(limit: 1000);
  }

  // Get disease frequency (for pie/bar chart)
  Future<Map<String, int>> getDiseaseFrequency() async {
    final predictions = await getAllPredictions();
    final Map<String, int> frequency = {};
    
    for (var p in predictions) {
      String disease = p['disease'] ?? 'Unknown';
      frequency[disease] = (frequency[disease] ?? 0) + 1;
    }
    
    return frequency;
  }

  // Get crop distribution
  Future<Map<String, int>> getCropDistribution() async {
    final predictions = await getAllPredictions();
    final Map<String, int> distribution = {};
    
    for (var p in predictions) {
      String crop = p['crop'] ?? 'Unknown';
      distribution[crop] = (distribution[crop] ?? 0) + 1;
    }
    
    return distribution;
  }

  // Get disease trends over time (last 7 days)
  Future<Map<String, Map<String, int>>> getDiseaseTrends() async {
    final predictions = await getAllPredictions();
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
      String disease = p['disease'] ?? 'Unknown';
      String dateKey = _getDateKeyFromTimestamp(timestamp);
      
      if (trends.containsKey(dateKey)) {
        trends[dateKey]![disease] = (trends[dateKey]![disease] ?? 0) + 1;
      }
    }
    
    return trends;
  }

  // Get summary statistics
  Future<Map<String, dynamic>> getSummaryStats() async {
    final predictions = await getAllPredictions();
    
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
      'mostRecent': total > 0 ? predictions.first : null,
    };
  }

  // Get most common disease
  Future<MapEntry<String, int>?> getMostCommonDisease() async {
    final frequency = await getDiseaseFrequency();
    if (frequency.isEmpty) return null;
    return frequency.entries.reduce((a, b) => a.value > b.value ? a : b);
  }

  // Generate mock data for testing
  Future<void> generateMockData() async {
    final List<String> mockDiseases = [
      'Common Rust', 'Gray Leaf Spot', 'Northern Leaf Blight', 'Healthy',
      'Late Blight', 'Early Blight', 'Leaf Mold', 'Stripe Rust', 'Blast'
    ];
    final List<String> mockCrops = ['maize', 'tomato', 'potato', 'wheat', 'rice'];
    
    for (int i = 0; i < 20; i++) {
      await _historyService.savePrediction({
        'crop': mockCrops[i % mockCrops.length],
        'disease': mockDiseases[i % mockDiseases.length],
        'confidence': 70 + (i * 1.5),
        'treatment': 'Mock treatment for testing',
        'imagePath': '',
        'timestamp': DateTime.now().subtract(Duration(days: i % 7)).toIso8601String(),
      });
    }
  }

  // Helper: Format date as "MM/DD"
  String _formatDateKey(DateTime date) {
    return '${date.month}/${date.day}';
  }

  // Helper: Extract date from timestamp
  String _getDateKeyFromTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return _formatDateKey(date);
    } catch (e) {
      return _formatDateKey(DateTime.now());
    }
  }
}
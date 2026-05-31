import 'package:sqflite/sqflite.dart';
import 'history_service.dart';

class FieldSurveyService {
  final HistoryService _historyService = HistoryService();

  Future<int> saveSurveySession({
    required String fieldName,
    required DateTime date,
    required int totalPhotos,
    required int healthyCount,
    required int diseasedCount,
    required Map<String, int> diseaseBreakdown,
  }) async {
    final db = await _historyService.database;
    return await db.insert('survey_sessions', {
      'fieldName': fieldName,
      'date': date.toIso8601String(),
      'totalPhotos': totalPhotos,
      'healthyCount': healthyCount,
      'diseasedCount': diseasedCount,
      'diseaseBreakdown': diseaseBreakdown.toString(),
    });
  }

  Future<List<Map<String, dynamic>>> getSessionsForField(String fieldName) async {
    final db = await _historyService.database;
    return await db.query(
      'survey_sessions',
      where: 'fieldName = ?',
      whereArgs: [fieldName],
      orderBy: 'date DESC',
    );
  }

  Future<List<String>> getAllFieldNames() async {
    final db = await _historyService.database;
    final result = await db.rawQuery('SELECT DISTINCT fieldName FROM survey_sessions');
    return result.map((row) => row['fieldName'] as String).toList();
  }

  Future<Map<String, dynamic>> getFieldSummary(String fieldName) async {
    final sessions = await getSessionsForField(fieldName);
    
    int totalPhotos = 0;
    int totalHealthy = 0;
    int totalDiseased = 0;
    
    for (var session in sessions) {
      totalPhotos += session['totalPhotos'] as int;
      totalHealthy += session['healthyCount'] as int;
      totalDiseased += session['diseasedCount'] as int;
    }
    
    return {
      'fieldName': fieldName,
      'totalSessions': sessions.length,
      'totalPhotos': totalPhotos,
      'healthyCount': totalHealthy,
      'diseasedCount': totalDiseased,
      'healthRate': totalPhotos > 0 ? (totalHealthy / totalPhotos * 100).toStringAsFixed(1) : '0',
      'diseaseRate': totalPhotos > 0 ? (totalDiseased / totalPhotos * 100).toStringAsFixed(1) : '0',
    };
  }

  Future<Map<String, dynamic>> compareFields(String field1, String field2) async {
    final summary1 = await getFieldSummary(field1);
    final summary2 = await getFieldSummary(field2);
    
    return {
      'field1': summary1,
      'field2': summary2,
      'comparison': {
        'healthierField': double.parse(summary1['healthRate']) > double.parse(summary2['healthRate']) ? field1 : field2,
        'difference': (double.parse(summary1['healthRate']) - double.parse(summary2['healthRate'])).abs().toStringAsFixed(1),
      }
    };
  }
}

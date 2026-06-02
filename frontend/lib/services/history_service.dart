import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'supabase_service.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static Database? _database;
  final SupabaseService _supabase = SupabaseService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'crop_disease.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE predictions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            crop TEXT,
            disease TEXT,
            confidence REAL,
            treatment TEXT,
            imagePath TEXT,
            timestamp TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<void> savePrediction(Map<String, dynamic> prediction) async {
    final db = await database;
    
    final id = await db.insert('predictions', {
      'crop': prediction['crop'],
      'disease': prediction['disease'],
      'confidence': prediction['confidence'],
      'treatment': prediction['treatment'],
      'imagePath': prediction['imagePath'],
      'timestamp': prediction['timestamp'],
      'synced': 0,
    });
    
    if (_supabase.isLoggedIn) {
      await _supabase.savePrediction(prediction);
      await db.update('predictions', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<List<Map<String, dynamic>>> getPredictions({int limit = 1000, bool includeDemo = false}) async {
    final db = await database;
    final localPredictions = await db.query(
      'predictions',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    
    // Handle null id safely
    final safeLocal = localPredictions.map((p) {
      return {
        ...p,
        'id': p['id'] as int? ?? 0,
      };
    }).toList();
    
    if (_supabase.isLoggedIn) {
      final cloudPredictions = await _supabase.loadPredictions();
      final allPredictions = [...safeLocal, ...cloudPredictions];
      allPredictions.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      return allPredictions.take(limit).toList();
    }
    
    return safeLocal;
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('predictions');
  }

  Future<void> deletePrediction(int id) async {
    final db = await database;
    await db.delete('predictions', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> syncToCloud() async {
    if (!_supabase.isLoggedIn) return;
    
    final db = await database;
    final unsynced = await db.query('predictions', where: 'synced = 0');
    
    for (var pred in unsynced) {
      await _supabase.savePrediction({
        'crop': pred['crop'],
        'disease': pred['disease'],
        'confidence': pred['confidence'],
        'treatment': pred['treatment'],
        'imagePath': pred['imagePath'],
        'timestamp': pred['timestamp'],
      });
      await db.update('predictions', {'synced': 1}, where: 'id = ?', whereArgs: [pred['id']]);
    }
    
    print('✅ Synced ${unsynced.length} predictions to cloud');
  }
}

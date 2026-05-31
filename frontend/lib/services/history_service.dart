import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static Database? _database;

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
      version: 2,  // ✅ Updated to version 2
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE predictions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            crop TEXT,
            disease TEXT,
            confidence REAL,
            treatment TEXT,
            imagePath TEXT,
            timestamp TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE survey_sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fieldName TEXT,
            date TEXT,
            totalPhotos INTEGER,
            healthyCount INTEGER,
            diseasedCount INTEGER,
            diseaseBreakdown TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // If upgrading from version 1 to 2, add the new table
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE survey_sessions(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fieldName TEXT,
              date TEXT,
              totalPhotos INTEGER,
              healthyCount INTEGER,
              diseasedCount INTEGER,
              diseaseBreakdown TEXT
            )
          ''');
        }
      },
    );
  }

  Future<int> savePrediction(Map<String, dynamic> prediction) async {
    final db = await database;
    return await db.insert('predictions', prediction);
  }

  Future<List<Map<String, dynamic>>> getPredictions({int limit = 50}) async {
    final db = await database;

    return await db.query(
      'predictions',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  Future<void> deletePrediction(int id) async {
    final db = await database;

    await db.delete(
      'predictions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('predictions');
  }
}
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    // Name geändert, um sauberen Neustart zu erzwingen (Tabelle neu)
    final path = join(dbPath, 'trt_tracker_v3.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. User Profile
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        name TEXT,
        weight REAL,
        height INTEGER,
        body_fat_percentage REAL,
        correction_factor REAL,
        preferred_unit TEXT,
        birth_date INTEGER,
        therapy_start INTEGER,
        created_at INTEGER,
        start_of_week INTEGER DEFAULT 1
      )
    ''');

    // Initialen leeren User anlegen
    await db.execute(
      "INSERT INTO user_profile (id, correction_factor) VALUES ('1', 1.0)",
    );

    // 2. Injektions-Historie
    await db.execute('''
      CREATE TABLE injections (
        id TEXT PRIMARY KEY,
        timestamp INTEGER,
        amount_mg REAL,
        ester_index INTEGER,
        method_index INTEGER,
        spot TEXT,
        created_at INTEGER
      )
    ''');

    // 3. Blutbilder
    await db.execute('''
      CREATE TABLE lab_results (
        id TEXT PRIMARY KEY,
        timestamp_drawn INTEGER,
        measured_value_raw REAL,
        unit_raw TEXT,
        value_normalized_ng_ml REAL,
        used_for_calibration INTEGER DEFAULT 0,
        resulting_correction_factor REAL, 
        created_at INTEGER
      )
    ''');

    // 4. NEU: Injektions-PLÄNE
    await db.execute('''
      CREATE TABLE injection_plans (
        id TEXT PRIMARY KEY,
        amount_mg REAL,
        ester_index INTEGER,
        method_index INTEGER,
        interval_days INTEGER,
        next_due_date INTEGER,
        reminder_hour INTEGER,
        reminder_minute INTEGER,
        is_active INTEGER DEFAULT 1,
        spot TEXT
      )
    ''');

    print("✅ Datenbank Tabellen (v3) korrekt erstellt!");
  }
}

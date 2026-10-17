import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/database_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute(HeroTable.createTableQuery);
    await _createWellbeingTables(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createWellbeingTables(db);
    }
  }

  Future<void> _createWellbeingTables(Database db) async {
    await db.execute(MoodTable.createTableQuery);
    await db.execute(ExerciseSessionTable.createTableQuery);
    await db.execute(CommunityPostTable.createTableQuery);
    await db.execute(CommunityCommentTable.createTableQuery);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

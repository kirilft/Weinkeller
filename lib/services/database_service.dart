import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'weinkeller.db'),
      onCreate: (db, version) async {
        // Create a table to store pending data
        await db.execute('''
          CREATE TABLE pending_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            density REAL,
            wineId INTEGER
          )
        ''');
      },
      version: 1,
    );
  }

  Future<int> insertPendingEntry(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('pending_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getPendingEntries() async {
    final db = await database;
    return await db.query('pending_entries');
  }

  Future<int> deletePendingEntry(int id) async {
    final db = await database;
    return await db.delete('pending_entries', where: 'id = ?', whereArgs: [id]);
  }
}

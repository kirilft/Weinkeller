import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show VoidCallback;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  /// A global (static) callback we can call whenever pending entries change
  static VoidCallback? onPendingEntriesChanged;

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

  /// Insert a new pending entry
  Future<int> insertPendingEntry(Map<String, dynamic> entry) async {
    final db = await database;
    final id = await db.insert('pending_entries', entry);

    // Notify watchers that pending entries changed
    onPendingEntriesChanged?.call();

    return id;
  }

  /// Retrieve all pending entries
  Future<List<Map<String, dynamic>>> getPendingEntries() async {
    final db = await database;
    return await db.query('pending_entries');
  }

  /// Returns how many pending entries there are
  Future<int> getPendingChangesCount() async {
    final entries = await getPendingEntries();
    return entries.length;
  }

  /// Delete a single pending entry by ID
  Future<void> deletePendingEntry(int id) async {
    final db = await database;
    await db.delete(
      'pending_entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Notify watchers
    onPendingEntriesChanged?.call();
  }

  /// Delete all pending entries
  Future<void> deleteAllPendingEntries() async {
    final db = await database;
    await db.delete('pending_entries');

    // Notify watchers
    onPendingEntriesChanged?.call();
  }

  /// Re-upload all pending entries, then remove them on success
  Future<void> reuploadAllPendingEntries() async {
    final db = await database;
    final allPending = await getPendingEntries();

    // A simple example: for each pending entry, "upload" it,
    // then delete. In your real code, you'd call your API, etc.
    for (final entry in allPending) {
      try {
        // Example: await ApiService.uploadEntry(entry);
        // If successful, remove from DB
        await db.delete(
          'pending_entries',
          where: 'id = ?',
          whereArgs: [entry['id']],
        );
      } catch (e) {
        // If upload fails, keep it in DB to retry
        print('[DatabaseService] Reupload failed for $entry: $e');
      }
    }

    // Notify watchers
    onPendingEntriesChanged?.call();
  }
}

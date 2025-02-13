import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // A broadcast StreamController to emit changes in pending entries count.
  final StreamController<int> _pendingChangesController =
      StreamController<int>.broadcast();

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    // Initialize stream with current count
    _updatePendingChangesCount();
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

  // Expose the stream so that the UI can listen to changes.
  Stream<int> get pendingChangesStream => _pendingChangesController.stream;

  // Helper to fetch and update the pending changes count.
  Future<int> _updatePendingChangesCount() async {
    final count = await getPendingChangesCount();
    _pendingChangesController.add(count);
    return count;
  }

  /// Insert a new pending entry.
  Future<int> insertPendingEntry(Map<String, dynamic> entry) async {
    final db = await database;
    final id = await db.insert('pending_entries', entry);
    await _updatePendingChangesCount();
    return id;
  }

  /// Retrieve all pending entries.
  Future<List<Map<String, dynamic>>> getPendingEntries() async {
    final db = await database;
    return await db.query('pending_entries');
  }

  /// Returns how many pending entries there are.
  Future<int> getPendingChangesCount() async {
    final entries = await getPendingEntries();
    return entries.length;
  }

  /// Delete a single pending entry by ID.
  Future<void> deletePendingEntry(int id) async {
    final db = await database;
    await db.delete('pending_entries', where: 'id = ?', whereArgs: [id]);
    await _updatePendingChangesCount();
  }

  /// Delete all pending entries.
  Future<void> deleteAllPendingEntries() async {
    final db = await database;
    await db.delete('pending_entries');
    await _updatePendingChangesCount();
  }

  /// Re-upload all pending entries, then remove them on success.
  Future<void> reuploadAllPendingEntries() async {
    final db = await database;
    final allPending = await getPendingEntries();

    for (final entry in allPending) {
      try {
        // Replace with your actual API upload logic.
        // await ApiService.uploadEntry(entry);
        await db.delete(
          'pending_entries',
          where: 'id = ?',
          whereArgs: [entry['id']],
        );
      } catch (e) {
        print('[DatabaseService] Reupload failed for $entry: $e');
      }
    }

    await _updatePendingChangesCount();
  }

  /// Dispose the stream controller when it's no longer needed.
  void dispose() {
    _pendingChangesController.close();
  }
}

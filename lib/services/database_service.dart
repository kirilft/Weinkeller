import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // A broadcast StreamController to emit changes in pending operations count.
  final StreamController<int> _pendingOperationsController =
      StreamController<int>.broadcast();

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    _updatePendingOperationsCount();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'weinkeller.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_operations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operationType TEXT,
            payload TEXT,
            timestamp TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  // Expose the stream so that the UI can listen to changes.
  Stream<int> get pendingOperationsStream =>
      _pendingOperationsController.stream;

  Future<int> _updatePendingOperationsCount() async {
    final count = await getPendingOperationsCount();
    _pendingOperationsController.add(count);
    return count;
  }

  /// Insert a new pending operation.
  Future<int> insertPendingOperation(Map<String, dynamic> operation) async {
    final db = await database;
    final id = await db.insert('pending_operations', operation);
    await _updatePendingOperationsCount();
    return id;
  }

  /// Retrieve all pending operations.
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await database;
    return await db.query('pending_operations');
  }

  /// Returns the number of pending operations.
  Future<int> getPendingOperationsCount() async {
    final operations = await getPendingOperations();
    return operations.length;
  }

  /// Delete a single pending operation by ID.
  Future<void> deletePendingOperation(int id) async {
    final db = await database;
    await db.delete('pending_operations', where: 'id = ?', whereArgs: [id]);
    await _updatePendingOperationsCount();
  }

  /// Delete all pending operations.
  Future<void> deleteAllPendingOperations() async {
    final db = await database;
    await db.delete('pending_operations');
    await _updatePendingOperationsCount();
  }

  /// Re-upload all pending operations, then remove them on success.
  Future<void> reuploadAllPendingOperations() async {
    final db = await database;
    final allOperations = await getPendingOperations();
    for (final operation in allOperations) {
      try {
        // Replace with your actual API upload logic, e.g.:
        // await ApiManager.uploadOperation(operation);
        await db.delete('pending_operations',
            where: 'id = ?', whereArgs: [operation['id']]);
      } catch (e) {
        print('[DatabaseService] Reupload failed for $operation: $e');
      }
    }
    await _updatePendingOperationsCount();
  }

  /// Dispose the stream controller when it's no longer needed.
  void dispose() {
    _pendingOperationsController.close();
  }
}

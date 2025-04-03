import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

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
    await _updatePendingOperationsCount();
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
        // Create a table for caching wine types.
        await db.execute('''
          CREATE TABLE cached_wine_types (
            id TEXT PRIMARY KEY,
            name TEXT
          )
        ''');

        // Create a table for caching additive types.
        await db.execute('''
          CREATE TABLE cached_additive_types (
            id TEXT PRIMARY KEY,
            type TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  // Expose the stream so that the UI can listen for changes.
  Stream<int> get pendingOperationsStream =>
      _pendingOperationsController.stream;

  Future<int> _updatePendingOperationsCount() async {
    final count = await getPendingOperationsCount();
    _pendingOperationsController.add(count);
    return count;
  }

  /// Inserts a new pending operation.
  Future<int> insertPendingOperation(Map<String, dynamic> operation) async {
    final db = await database;
    final id = await db.insert('pending_operations', operation);
    await _updatePendingOperationsCount();
    return id;
  }

  /// Retrieves all pending operations.
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await database;
    return db.query('pending_operations');
  }

  /// Returns the count of pending operations.
  Future<int> getPendingOperationsCount() async {
    final operations = await getPendingOperations();
    return operations.length;
  }

  /// Deletes a single pending operation by its ID.
  Future<void> deletePendingOperation(int id) async {
    final db = await database;
    await db.delete('pending_operations', where: 'id = ?', whereArgs: [id]);
    await _updatePendingOperationsCount();
  }

  /// Deletes all pending operations.
  Future<void> deleteAllPendingOperations() async {
    final db = await database;
    await db.delete('pending_operations');
    await _updatePendingOperationsCount();
  }

  /// Re-uploads all pending operations.
  /// Here we simulate a successful upload by deleting each pending operation.
  Future<void> reuploadAllPendingOperations() async {
    final db = await database;
    final allOperations = await getPendingOperations();

    for (final operation in allOperations) {
      try {
        // Simulate a successful upload.
        debugPrint(
            '[DatabaseService] Simulating upload for operation: $operation');
        await db.delete('pending_operations',
            where: 'id = ?', whereArgs: [operation['id']]);
      } catch (e) {
        debugPrint('[DatabaseService] Reupload failed for $operation: $e');
      }
    }

    await _updatePendingOperationsCount();
  }

  /// Inserts or updates a cached wine type.
  Future<void> insertOrUpdateWineType(Map<String, dynamic> wineType) async {
    final db = await database;
    await db.insert(
      'cached_wine_types',
      wineType,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all cached wine types.
  Future<List<Map<String, dynamic>>> getCachedWineTypes() async {
    final db = await database;
    return db.query('cached_wine_types');
  }

  /// Clears all cached wine types.
  Future<void> clearCachedWineTypes() async {
    final db = await database;
    await db.delete('cached_wine_types');
  }

  /// Inserts or updates a cached additive type.
  Future<void> insertOrUpdateAdditiveType(
      Map<String, dynamic> additiveType) async {
    final db = await database;
    await db.insert(
      'cached_additive_types',
      additiveType,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all cached additive types.
  Future<List<Map<String, dynamic>>> getCachedAdditiveTypes() async {
    final db = await database;
    return db.query('cached_additive_types');
  }

  /// Clears all cached additive types.
  Future<void> clearCachedAdditiveTypes() async {
    final db = await database;
    await db.delete('cached_additive_types');
  }

  /// Dispose the stream controller when it's no longer needed.
  void dispose() {
    _pendingOperationsController.close();
  }
}

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
    // Initialize the count when the database is ready.
    await _updatePendingOperationsCount();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'weinkeller.db'),
      onCreate: (db, version) async {
        // Table for operations that need to be synced later.
        await db.execute('''
          CREATE TABLE pending_operations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operationType TEXT,
            payload TEXT,
            timestamp TEXT
          )
        ''');
        // Table for caching additive types (fetched from API).
        await db.execute('''
          CREATE TABLE cached_additive_types (
            id TEXT PRIMARY KEY, -- Assuming AdditiveType ID is TEXT (UUID)
            type TEXT
          )
        ''');
        // Table for caching wine barrels (fetched from API).
        await db.execute('''
          CREATE TABLE cached_wine_barrels (
            id TEXT PRIMARY KEY, -- Assuming WineBarrel ID is TEXT (UUID)
            name TEXT
            -- Add other fields here if needed for offline display, e.g., volumeInLitre REAL
          )
        ''');
      },
      // IMPORTANT: Increment version if schema changes. Add migration logic in onUpgrade if needed.
      version: 1,
    );
  }

  // Expose the stream so that the UI can listen for changes in pending operations count.
  Stream<int> get pendingOperationsStream =>
      _pendingOperationsController.stream;

  /// Updates the count and notifies listeners.
  Future<int> _updatePendingOperationsCount() async {
    final count = await getPendingOperationsCount();
    if (!_pendingOperationsController.isClosed) {
      _pendingOperationsController.add(count);
    }
    return count;
  }

  /// Inserts a new pending operation.
  Future<int> insertPendingOperation(Map<String, dynamic> operation) async {
    final db = await database;
    final id = await db.insert('pending_operations', operation);
    await _updatePendingOperationsCount(); // Update count after insert
    debugPrint('[DatabaseService] Inserted pending operation ID: $id');
    return id;
  }

  /// Retrieves all pending operations.
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await database;
    final List<Map<String, dynamic>> operations =
        await db.query('pending_operations');
    debugPrint(
        '[DatabaseService] Retrieved ${operations.length} pending operations.');
    return operations;
  }

  /// Returns the count of pending operations.
  Future<int> getPendingOperationsCount() async {
    final db = await database;
    // Use count aggregation for efficiency
    final result = await db.rawQuery('SELECT COUNT(*) FROM pending_operations');
    final count = Sqflite.firstIntValue(result) ?? 0;
    debugPrint('[DatabaseService] Pending operations count: $count');
    return count;
  }

  /// Deletes a single pending operation by its ID.
  Future<void> deletePendingOperation(int id) async {
    final db = await database;
    final deletedRows =
        await db.delete('pending_operations', where: 'id = ?', whereArgs: [id]);
    await _updatePendingOperationsCount(); // Update count after delete
    debugPrint(
        '[DatabaseService] Deleted $deletedRows pending operation(s) with ID: $id');
  }

  /// Deletes all pending operations.
  Future<void> deleteAllPendingOperations() async {
    final db = await database;
    final deletedRows = await db.delete('pending_operations');
    await _updatePendingOperationsCount(); // Update count after deleting all
    debugPrint(
        '[DatabaseService] Deleted all $deletedRows pending operations.');
  }

  /// Re-uploads all pending operations.
  /// Placeholder: In a real app, this would involve calling the appropriate ApiService methods.
  /// Here we just simulate success by deleting them.
  Future<void> reuploadAllPendingOperations() async {
    final db = await database;
    final allOperations = await getPendingOperations();
    int successfullyProcessed = 0;

    for (final operation in allOperations) {
      try {
        // TODO: Implement actual API call based on operation['operationType'] and operation['payload']
        debugPrint(
            '[DatabaseService] Simulating re-upload for operation: ${operation['id']} - ${operation['operationType']}');
        // Simulate success by deleting the local entry
        await db.delete('pending_operations',
            where: 'id = ?', whereArgs: [operation['id']]);
        successfullyProcessed++;
      } catch (e) {
        // Log error but continue with other operations
        debugPrint(
            '[DatabaseService] Reupload failed for operation ${operation['id']}: $e');
      }
    }

    debugPrint(
        '[DatabaseService] Finished re-upload attempt. Processed $successfullyProcessed/${allOperations.length} operations.');
    await _updatePendingOperationsCount(); // Update count after processing all
  }

  // --- Additive Types Cache ---

  /// Inserts or updates a cached additive type.
  Future<void> insertOrUpdateAdditiveType(
      Map<String, dynamic> additiveType) async {
    final db = await database;
    // Ensure required fields are present
    if (additiveType['id'] == null) {
      debugPrint(
          '[DatabaseService] Error: Cannot cache AdditiveType without an ID.');
      return;
    }
    await db.insert(
      'cached_additive_types',
      {
        // Explicitly map to ensure correct columns
        'id': additiveType['id'],
        'type': additiveType['type']
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // debugPrint('[DatabaseService] Cached/Updated AdditiveType ID: ${additiveType['id']}');
  }

  /// Retrieves all cached additive types.
  Future<List<Map<String, dynamic>>> getCachedAdditiveTypes() async {
    final db = await database;
    final List<Map<String, dynamic>> types =
        await db.query('cached_additive_types');
    debugPrint(
        '[DatabaseService] Retrieved ${types.length} cached additive types.');
    return types;
  }

  /// Clears all cached additive types.
  Future<void> clearCachedAdditiveTypes() async {
    final db = await database;
    final deletedRows = await db.delete('cached_additive_types');
    debugPrint('[DatabaseService] Cleared $deletedRows cached additive types.');
  }

  // --- Wine Barrels Cache ---

  /// Inserts or updates a cached wine barrel (currently only ID and name).
  Future<void> insertOrUpdateWineBarrel(Map<String, dynamic> wineBarrel) async {
    final db = await database;
    // Ensure required fields are present
    if (wineBarrel['id'] == null) {
      debugPrint(
          '[DatabaseService] Error: Cannot cache WineBarrel without an ID.');
      return;
    }
    await db.insert(
      'cached_wine_barrels',
      {
        // Explicitly map to ensure correct columns
        'id': wineBarrel['id'],
        'name': wineBarrel['name'] // Assuming 'name' exists in the map
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // debugPrint('[DatabaseService] Cached/Updated WineBarrel ID: ${wineBarrel['id']}');
  }

  /// Retrieves all cached wine barrels (currently only ID and name).
  Future<List<Map<String, dynamic>>> getCachedWineBarrels() async {
    final db = await database;
    final List<Map<String, dynamic>> barrels =
        await db.query('cached_wine_barrels');
    debugPrint(
        '[DatabaseService] Retrieved ${barrels.length} cached wine barrels.');
    return barrels;
  }

  /// Clears all cached wine barrels.
  Future<void> clearCachedWineBarrels() async {
    final db = await database;
    final deletedRows = await db.delete('cached_wine_barrels');
    debugPrint('[DatabaseService] Cleared $deletedRows cached wine barrels.');
  }

  /// Dispose the stream controller when the service is no longer needed.
  /// Typically called when the app is closing or the provider is disposed.
  void dispose() {
    _pendingOperationsController.close();
    debugPrint('[DatabaseService] Disposed.');
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'api_service.dart'; // Assuming ApiService and exceptions are defined here
import 'database_service.dart';
import 'history_service.dart';

/// ApiManager acts as a facade over ApiService, DatabaseService, and HistoryService.
/// It orchestrates API calls, local caching, history logging, and offline operation handling.
class ApiManager {
  final ApiService apiService;
  final DatabaseService databaseService;
  final HistoryService historyService;

  ApiManager({
    required this.apiService,
    required this.databaseService,
    required this.historyService,
  });

  // --------------------------------------------------------------------------
  // Group 1: Methods primarily for fetching data with local caching fallback.
  // These methods attempt to fetch fresh data from the API. If successful,
  // they update the local cache (managed by SyncService). If the API call fails
  // (e.g., network error), they attempt to return data from the local cache.
  // --------------------------------------------------------------------------

  /// Fetch the current user's data. (No caching implemented here yet)
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    debugPrint('[ApiManager] getCurrentUser() called.');
    try {
      // TODO: Consider caching user data if needed offline.
      final result = await apiService.getCurrentUser(token: token);
      debugPrint('[ApiManager] getCurrentUser() succeeded: $result');
      return result;
    } catch (e) {
      debugPrint('[ApiManager] Error in getCurrentUser: $e');
      // TODO: Implement fallback to cached user data if applicable.
      rethrow;
    }
  }

  /// Fetch a specific additive by ID. (No caching implemented here yet)
  Future<Map<String, dynamic>> getAdditive(String id, String token) async {
    // Note: Changed id type to String to match typical UUID usage. Adjust if needed.
    debugPrint('[ApiManager] getAdditive() called with id: $id');
    try {
      // TODO: Consider caching individual additives if needed offline.
      final result = await apiService.getAdditive(id, token: token);
      debugPrint('[ApiManager] getAdditive() succeeded: $result');
      return result;
    } catch (e) {
      debugPrint('[ApiManager] Error in getAdditive: $e');
      // TODO: Implement fallback to cached additive data if applicable.
      rethrow;
    }
  }

  /// Fetch all AdditiveTypes from the server, falling back to local cache on error.
  /// The cache itself is updated periodically by SyncService.
  Future<List<Map<String, dynamic>>> getAllAdditiveTypes(String token) async {
    debugPrint('[ApiManager] getAllAdditiveTypes() called.');
    try {
      // Always try to fetch fresh data first
      final remoteList = await apiService.getAllAdditiveTypes(token: token);
      debugPrint(
          '[ApiManager] Fetched remote additive types: ${remoteList.length} items.');
      // Note: SyncService is responsible for updating the cache periodically.
      // This method doesn't directly update cache on read.
      return remoteList; // Return the fresh data from API
    } catch (e) {
      debugPrint(
          '[ApiManager] Error fetching AdditiveTypes from API: $e. Trying cache...');
      // Fallback to local cache if API fails
      try {
        final cached = await databaseService.getCachedAdditiveTypes();
        if (cached.isEmpty) {
          debugPrint(
              '[ApiManager] No cached additive types found. Rethrowing API error.');
          rethrow; // Rethrow API error if cache is also empty
        } else {
          debugPrint(
              '[ApiManager] Returning ${cached.length} cached additive types from DB.');
          return cached; // Return cached data
        }
      } catch (cacheError) {
        debugPrint(
            '[ApiManager] Error reading from AdditiveType cache: $cacheError. Rethrowing original API error.');
        rethrow; // Rethrow the original API error if cache read fails
      }
    }
  }

  /// Fetch all WineTypes from the server, falling back to local cache on error.
  /// The cache itself is updated periodically by SyncService.
  Future<List<Map<String, dynamic>>> getAllWineTypesWithCaching(
      String token) async {
    debugPrint('[ApiManager] getAllWineTypesWithCaching() called.');
    try {
      // Always try to fetch fresh data first
      final remoteList = await apiService.getAllWineTypes(token: token);
      debugPrint(
          '[ApiManager] Fetched remote wine types: ${remoteList.length} items.');
      // Cache is updated by SyncService in the background.
      return remoteList; // Return the fresh data from API
    } catch (e) {
      debugPrint(
          '[ApiManager] Error fetching WineTypes from API: $e. Trying cache...');
      // Fallback to local cache if API fails
      try {
        final cached =
            await databaseService.getCachedWineTypes(); // Use the new DB method
        if (cached.isEmpty) {
          debugPrint(
              '[ApiManager] No cached wine types found. Rethrowing API error.');
          rethrow; // Rethrow API error if cache is also empty
        } else {
          debugPrint(
              '[ApiManager] Returning ${cached.length} cached wine types from DB.');
          return cached; // Return cached data
        }
      } catch (cacheError) {
        debugPrint(
            '[ApiManager] Error reading from WineType cache: $cacheError. Rethrowing original API error.');
        rethrow; // Rethrow the original API error if cache read fails
      }
    }
  }

  /// Fetch all WineBarrels from the server, falling back to local cache on error.
  /// The cache itself is updated periodically by SyncService.
  Future<List<Map<String, dynamic>>> getAllWineBarrelsWithCaching(
      String token) async {
    debugPrint('[ApiManager] getAllWineBarrelsWithCaching() called.');
    try {
      // Always try to fetch fresh data first
      final remoteList = await apiService.getAllWineBarrels(token: token);
      debugPrint(
          '[ApiManager] Fetched remote wine barrels: ${remoteList.length} items.');
      // Cache is updated by SyncService in the background.
      return remoteList; // Return the full data fetched from API
    } catch (e) {
      debugPrint(
          '[ApiManager] Error fetching WineBarrels from API: $e. Trying cache...');
      // Fallback to local cache if API fails
      try {
        final cached = await databaseService.getCachedWineBarrels();
        if (cached.isEmpty) {
          debugPrint(
              '[ApiManager] No cached wine barrels found. Rethrowing API error.');
          rethrow; // Rethrow API error if cache is also empty
        } else {
          debugPrint(
              '[ApiManager] Returning ${cached.length} cached wine barrels from DB.');
          // IMPORTANT: Returning cached data which currently only has id and name.
          // UI needs to handle potentially incomplete data when offline.
          return cached;
        }
      } catch (cacheError) {
        debugPrint(
            '[ApiManager] Error reading from WineBarrel cache: $cacheError. Rethrowing original API error.');
        rethrow; // Rethrow the original API error if cache read fails
      }
    }
  }

  // --------------------------------------------------------------------------
  // Group 2: Methods for creating or modifying data (write operations).
  // These methods attempt to perform the operation via the API.
  // If successful, they log the operation to history.
  // If the API call fails due to a network error (offline), they save
  // the operation locally in the 'pending_operations' table for later sync.
  // --------------------------------------------------------------------------

  /// Creates an additive both online (if possible) and logs it to history.
  /// If offline, the operation is saved to pending operations.
  /// Expects `additive` map with keys matching the API schema (`additiveTypeId`, `wineId`, etc.).
  Future<Map<String, dynamic>> createAdditive(
      Map<String, dynamic> additive, String token) async {
    debugPrint('[ApiManager] createAdditive() called with additive: $additive');

    // Prepare payload exactly as needed by ApiService.createAdditive
    final apiPayload = {
      'date': additive['date'] ?? DateTime.now().toIso8601String(),
      'amountGrammsPerLitre': additive['amountGrammsPerLitre'],
      'additiveTypeId': additive['additiveTypeId']?.toString(),
      'wineId': additive['wineId']?.toString(),
    };

    // Validate payload before proceeding
    if (apiPayload['amountGrammsPerLitre'] == null ||
        apiPayload['additiveTypeId'] == null ||
        apiPayload['wineId'] == null) {
      final errorMsg =
          '[ApiManager] Error: Missing required fields for createAdditive. Payload: $apiPayload';
      debugPrint(errorMsg);
      throw ArgumentError(errorMsg);
    }

    debugPrint(
        '[ApiManager] Prepared API payload for createAdditive: $apiPayload');

    try {
      final result = await apiService.createAdditive(apiPayload, token: token);
      debugPrint('[ApiManager] Additive created successfully via API: $result');

      final historyEntry = {
        'operationType': 'createAdditive',
        'payload': apiPayload,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Synced',
        'result': result,
      };
      await historyService.addHistoryEntry(historyEntry);
      debugPrint(
          '[ApiManager] History entry added for successful createAdditive.');
      return result;
    } catch (e) {
      debugPrint('[ApiManager] Error in createAdditive API call: $e');
      if (e is NoResponseException ||
          e.toString().contains('SocketException')) {
        debugPrint(
            '[ApiManager] Network error detected. Saving createAdditive operation locally.');
        final operation = {
          'operationType': 'createAdditive',
          'payload': jsonEncode(apiPayload),
          'timestamp': DateTime.now().toIso8601String(),
        };
        try {
          await databaseService.insertPendingOperation(operation);
          debugPrint(
              '[ApiManager] createAdditive operation saved locally for later commit.');
          throw OfflineOperationQueuedException(
              'Create Additive operation queued locally.');
        } catch (dbError) {
          debugPrint(
              '[ApiManager] CRITICAL: Failed to save pending operation locally: $dbError');
          rethrow;
        }
      } else {
        debugPrint('[ApiManager] Non-network API error. Rethrowing.');
        rethrow;
      }
    }
  }

  /// Updates an additive (if possible) and logs it to history.
  /// If offline, the operation is saved to pending operations.
  /// Expects `additive` map with keys matching the API schema.
  Future<void> updateAdditive(
      String id, Map<String, dynamic> additive, String token) async {
    // Note: Changed id type to String.
    debugPrint(
        '[ApiManager] updateAdditive() called for id: $id with additive: $additive');

    // Prepare payload (similar validation as createAdditive might be needed)
    final apiPayload = {
      // Include fields allowed for update by the API
      'id': id, // Usually needed for PUT request body as well
      'date': additive['date'],
      'amountGrammsPerLitre': additive['amountGrammsPerLitre'],
      'additiveTypeId': additive['additiveTypeId']?.toString(),
      'wineId': additive['wineId']?.toString(),
    };
    // Remove null values if the API doesn't expect them for updates
    apiPayload.removeWhere((key, value) => value == null);

    debugPrint(
        '[ApiManager] Prepared API payload for updateAdditive: $apiPayload');

    try {
      // Attempt API update
      await apiService.updateAdditive(id, apiPayload, token: token);
      debugPrint('[ApiManager] updateAdditive() succeeded via API for id: $id');

      // Log to history
      final historyEntry = {
        'operationType': 'updateAdditive',
        'payload': {
          'id': id,
          'updateData': apiPayload
        }, // Log ID and the data sent
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Synced',
      };
      await historyService.addHistoryEntry(historyEntry);
      debugPrint(
          '[ApiManager] History entry added for successful updateAdditive.');
    } catch (e) {
      debugPrint('[ApiManager] Error in updateAdditive API call: $e');
      // Check for network error
      if (e is NoResponseException ||
          e.toString().contains('SocketException')) {
        debugPrint(
            '[ApiManager] Network error detected. Saving updateAdditive operation locally.');
        // Save operation locally
        final operation = {
          'operationType': 'updateAdditive',
          // Store ID and payload needed for the update
          'payload': jsonEncode({'id': id, 'additive': apiPayload}),
          'timestamp': DateTime.now().toIso8601String(),
        };
        try {
          await databaseService.insertPendingOperation(operation);
          debugPrint(
              '[ApiManager] updateAdditive operation saved locally for later commit.');
          throw OfflineOperationQueuedException(
              'Update Additive operation queued locally.');
        } catch (dbError) {
          debugPrint(
              '[ApiManager] CRITICAL: Failed to save pending operation locally: $dbError');
          rethrow;
        }
      } else {
        // Rethrow other API errors
        debugPrint('[ApiManager] Non-network API error. Rethrowing.');
        rethrow;
      }
    }
  }

  /// Adds a fermentation entry both online (if possible) and logs it to history.
  /// If offline, the operation is saved to pending operations.
  Future<void> addFermentationEntry(
      String token, DateTime date, double density, String winebarrelid) async {
    debugPrint(
        '[ApiManager] addFermentationEntry() called with winebarrelid=$winebarrelid, density=$density, date=$date');

    // Prepare payload for API
    final apiPayload = {
      'date': DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
          .format(date.toUtc()), // Use UTC
      'density': density,
      'wineId': winebarrelid, // API expects 'wineId'
    };
    debugPrint(
        '[ApiManager] Prepared API payload for addFermentationEntry: $apiPayload');

    try {
      // Attempt API call
      await apiService.addFermentationEntry(
        token: token,
        date: date, // Pass original DateTime object if ApiService expects it
        density: density,
        winebarrelid: winebarrelid, // Pass original ID if ApiService expects it
      );
      debugPrint('[ApiManager] Fermentation entry added successfully via API.');

      // Log to history (consider fetching barrel name if needed for richer history)
      String wineNameForHistory = winebarrelid; // Default to ID
      try {
        // Optionally fetch barrel details for history logging, but handle potential errors
        final wineBarrel =
            await apiService.getWineBarrel(winebarrelid, token: token);
        wineNameForHistory =
            wineBarrel['name'] ?? winebarrelid; // Use name if available
      } catch (fetchError) {
        debugPrint(
            '[ApiManager] Could not fetch wine barrel name for history log: $fetchError');
      }

      final historyEntry = {
        'operationType': 'addFermentationEntry',
        'payload': {
          // Log data relevant to the operation
          'date': apiPayload['date'],
          'density': density,
          'wineId': winebarrelid,
          'wineName': wineNameForHistory, // Include fetched name if available
        },
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Synced',
      };
      await historyService.addHistoryEntry(historyEntry);
      debugPrint(
          '[ApiManager] History entry added for successful addFermentationEntry.');
    } catch (e) {
      debugPrint('[ApiManager] Error in addFermentationEntry API call: $e');
      // Check for network error
      if (e is NoResponseException ||
          e.toString().contains('SocketException')) {
        debugPrint(
            '[ApiManager] Network error detected. Saving addFermentationEntry operation locally.');
        // Save operation locally
        final operation = {
          'operationType': 'addFermentationEntry',
          'payload': jsonEncode(apiPayload), // Store the payload sent to API
          'timestamp': DateTime.now().toIso8601String(),
        };
        try {
          await databaseService.insertPendingOperation(operation);
          debugPrint(
              '[ApiManager] addFermentationEntry operation saved locally for later commit.');
          throw OfflineOperationQueuedException(
              'Add Fermentation Entry operation queued locally.');
        } catch (dbError) {
          debugPrint(
              '[ApiManager] CRITICAL: Failed to save pending operation locally: $dbError');
          rethrow;
        }
      } else {
        // Rethrow other API errors
        debugPrint('[ApiManager] Non-network API error. Rethrowing.');
        rethrow;
      }
    }
  }

  // --- Add other methods (delete, other creates/updates) following the same pattern ---
  // - Try API call.
  // - On success: log to history.
  // - On network error: save to pending operations, throw OfflineOperationQueuedException.
  // - On other API error: rethrow.
}

/// Custom exception to indicate an operation failed online but was queued locally.
class OfflineOperationQueuedException implements Exception {
  final String message;
  OfflineOperationQueuedException(this.message);

  @override
  String toString() => 'OfflineOperationQueuedException: $message';
}

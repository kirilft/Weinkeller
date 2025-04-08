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
  // --------------------------------------------------------------------------

  /// Fetch the current user's data. (No caching implemented here yet)
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    debugPrint('[ApiManager] getCurrentUser() called.');
    try {
      final result = await apiService.getCurrentUser(token: token);
      debugPrint('[ApiManager] getCurrentUser() succeeded: $result');
      return result;
    } catch (e) {
      debugPrint('[ApiManager] Error in getCurrentUser: $e');
      rethrow;
    }
  }

  /// Fetch a specific additive by ID. (No caching implemented here yet)
  Future<Map<String, dynamic>> getAdditive(String id, String token) async {
    debugPrint('[ApiManager] getAdditive() called with id: $id');
    try {
      final result = await apiService.getAdditive(id, token: token);
      debugPrint('[ApiManager] getAdditive() succeeded: $result');
      return result;
    } catch (e) {
      debugPrint('[ApiManager] Error in getAdditive: $e');
      rethrow;
    }
  }

  /// Fetch all AdditiveTypes from the server, falling back to local cache on error.
  Future<List<Map<String, dynamic>>> getAllAdditiveTypes(String token) async {
    debugPrint('[ApiManager] getAllAdditiveTypes() called.');
    try {
      final remoteList = await apiService.getAllAdditiveTypes(token: token);
      debugPrint(
          '[ApiManager] Fetched remote additive types: ${remoteList.length} items.');
      return remoteList;
    } catch (e) {
      // Catches API errors (network, server, etc.)
      debugPrint(
          '[ApiManager] Error fetching AdditiveTypes from API: $e. Trying cache...');
      try {
        final cached = await databaseService.getCachedAdditiveTypes();
        if (cached.isEmpty) {
          debugPrint(
              '[ApiManager] Cache for AdditiveTypes is empty. Returning empty list.');
          return [];
        } else {
          debugPrint(
              '[ApiManager] Returning ${cached.length} cached additive types from DB.');
          return cached;
        }
      } catch (cacheError) {
        // Catches errors specifically during cache read
        debugPrint(
            '[ApiManager] Error reading from AdditiveType cache: $cacheError. Returning empty list.');
        return [];
      }
    }
  }

  /// Fetch all WineTypes from the server, falling back to local cache on error.
  Future<List<Map<String, dynamic>>> getAllWineTypesWithCaching(
      String token) async {
    debugPrint('[ApiManager] getAllWineTypesWithCaching() called.');
    try {
      final remoteList = await apiService.getAllWineTypes(token: token);
      debugPrint(
          '[ApiManager] Fetched remote wine types: ${remoteList.length} items.');
      return remoteList;
    } catch (e) {
      // Catches API errors
      debugPrint(
          '[ApiManager] Error fetching WineTypes from API: $e. Trying cache...');
      try {
        final cached = await databaseService.getCachedWineTypes();
        if (cached.isEmpty) {
          debugPrint(
              '[ApiManager] Cache for WineTypes is empty. Returning empty list.');
          return [];
        } else {
          debugPrint(
              '[ApiManager] Returning ${cached.length} cached wine types from DB.');
          return cached;
        }
      } catch (cacheError) {
        // Catches errors specifically during cache read
        debugPrint(
            '[ApiManager] Error reading from WineType cache: $cacheError. Returning empty list.');
        return [];
      }
    }
  }

  /// Fetch all WineBarrels from the server, falling back to local cache on error.
  Future<List<Map<String, dynamic>>> getAllWineBarrelsWithCaching(
      String token) async {
    debugPrint('[ApiManager] getAllWineBarrelsWithCaching() called.');
    try {
      final remoteList = await apiService.getAllWineBarrels(token: token);
      debugPrint(
          '[ApiManager] Fetched remote wine barrels: ${remoteList.length} items.');
      return remoteList;
    } catch (e) {
      // Catches API errors
      debugPrint(
          '[ApiManager] Error fetching WineBarrels from API: $e. Trying cache...');
      try {
        final cached = await databaseService.getCachedWineBarrels();
        if (cached.isEmpty) {
          debugPrint(
              '[ApiManager] Cache for WineBarrels is empty. Returning empty list.');
          return [];
        } else {
          debugPrint(
              '[ApiManager] Returning ${cached.length} cached wine barrels from DB.');
          return cached;
        }
      } catch (cacheError) {
        // Catches errors specifically during cache read
        debugPrint(
            '[ApiManager] Error reading from WineBarrel cache: $cacheError. Returning empty list.');
        return [];
      }
    }
  }

  // --------------------------------------------------------------------------
  // Group 2: Methods for creating or modifying data (write operations).
  // --------------------------------------------------------------------------

  /// Creates an additive both online (if possible) and logs it to history.
  /// If offline, the operation is saved to pending operations.
  /// Expects `additive` map with keys coming from the UI layer.
  Future<Map<String, dynamic>> createAdditive(
      Map<String, dynamic> additive, String token) async {
    // Input `additive` map (from logs):
    // { 'winebarrelid': ..., 'type': ..., 'amount': ..., 'unit': ..., 'addedAt': ... }
    debugPrint('[ApiManager] createAdditive() called with input: $additive');

    // ** FIXED Key Mapping **
    // Map keys from UI input to keys expected by API schema
    final apiPayload = {
      // Use 'addedAt' from input if available, otherwise default to now
      'date': additive['addedAt'] ?? DateTime.now().toIso8601String(),
      // Use 'amount' from input for 'amountGrammsPerLitre'
      'amountGrammsPerLitre': additive['amount'],
      // Use 'type' from input for 'additiveTypeId'
      'additiveTypeId': additive['type']?.toString(),
      // Use 'winebarrelid' from input for 'wineId'
      'wineId': additive['winebarrelid']?.toString(),
    };
    debugPrint('[ApiManager] Mapped payload for API: $apiPayload');

    // Validate the *mapped* payload before proceeding
    // Ensure amount is a number (it was 1.0 in logs, so likely double/num)
    final amountValue = apiPayload['amountGrammsPerLitre'];
    if (amountValue == null || amountValue is! num) {
      final errorMsg =
          '[ApiManager] Error: Invalid or missing amount. Payload: $apiPayload';
      debugPrint(errorMsg);
      throw ArgumentError(errorMsg);
    }
    if (apiPayload['additiveTypeId'] == null) {
      final errorMsg =
          '[ApiManager] Error: Missing additive type ID. Payload: $apiPayload';
      debugPrint(errorMsg);
      throw ArgumentError(errorMsg);
    }
    if (apiPayload['wineId'] == null) {
      final errorMsg =
          '[ApiManager] Error: Missing wine ID (barrel ID). Payload: $apiPayload';
      debugPrint(errorMsg);
      throw ArgumentError(errorMsg);
    }
    // --- End Validation ---

    try {
      // Attempt to create via API using the correctly mapped payload
      final result = await apiService.createAdditive(apiPayload, token: token);
      debugPrint('[ApiManager] Additive created successfully via API: $result');

      // Log to history on success
      final historyEntry = {
        'operationType': 'createAdditive',
        'payload': apiPayload, // Log the payload sent to API
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Synced',
        'result': result,
      };
      await historyService.addHistoryEntry(historyEntry);
      debugPrint(
          '[ApiManager] History entry added for successful createAdditive.');
      return result; // Return the result from the API
    } catch (e) {
      debugPrint('[ApiManager] Error in createAdditive API call: $e');
      // Check if it's a network-related error (offline)
      if (e is NoResponseException ||
          e.toString().contains('SocketException')) {
        debugPrint(
            '[ApiManager] Network error detected. Saving createAdditive operation locally.');
        // Save operation locally for later sync
        final operation = {
          'operationType': 'createAdditive',
          'payload': jsonEncode(apiPayload), // Store the mapped payload
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
          rethrow; // Rethrow original API error if saving locally fails
        }
      } else {
        // For other API errors (e.g., 400 Bad Request, 500 Server Error), just rethrow.
        debugPrint('[ApiManager] Non-network API error. Rethrowing.');
        rethrow;
      }
    }
  }

  /// Updates an additive (if possible) and logs it to history.
  Future<void> updateAdditive(
      String id, Map<String, dynamic> additive, String token) async {
    // Assuming input `additive` map uses UI keys like 'amount', 'type', 'addedAt' etc.
    // Map them similarly to createAdditive if needed for the API PUT payload.
    debugPrint(
        '[ApiManager] updateAdditive() called for id: $id with input: $additive');

    // ** Potential Key Mapping Needed Here Too **
    // Map keys from UI input to keys expected by API schema for update
    final apiPayload = {
      'id': id,
      'date':
          additive['addedAt'] ?? additive['date'], // Check both potential keys
      'amountGrammsPerLitre':
          additive['amount'] ?? additive['amountGrammsPerLitre'],
      'additiveTypeId':
          (additive['type'] ?? additive['additiveTypeId'])?.toString(),
      'wineId': (additive['winebarrelid'] ?? additive['wineId'])?.toString(),
    };
    // Remove nulls ONLY if the API requires it for PUT/PATCH
    apiPayload.removeWhere((key, value) => value == null);

    debugPrint(
        '[ApiManager] Mapped payload for updateAdditive API: $apiPayload');

    // Add validation for mapped payload if necessary

    try {
      await apiService.updateAdditive(id, apiPayload,
          token: token); // Send mapped payload
      debugPrint('[ApiManager] updateAdditive() succeeded via API for id: $id');

      final historyEntry = {
        'operationType': 'updateAdditive',
        'payload': {'id': id, 'updateData': apiPayload},
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Synced',
      };
      await historyService.addHistoryEntry(historyEntry);
      debugPrint(
          '[ApiManager] History entry added for successful updateAdditive.');
    } catch (e) {
      debugPrint('[ApiManager] Error in updateAdditive API call: $e');
      if (e is NoResponseException ||
          e.toString().contains('SocketException')) {
        debugPrint(
            '[ApiManager] Network error detected. Saving updateAdditive operation locally.');
        final operation = {
          'operationType': 'updateAdditive',
          'payload': jsonEncode(
              {'id': id, 'additive': apiPayload}), // Save mapped payload
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
        debugPrint('[ApiManager] Non-network API error. Rethrowing.');
        rethrow;
      }
    }
  }

  /// Adds a fermentation entry both online (if possible) and logs it to history.
  Future<void> addFermentationEntry(
      String token, DateTime date, double density, String winebarrelid) async {
    // This method seems to use correct keys directly, no mapping needed here based on previous logs
    debugPrint(
        '[ApiManager] addFermentationEntry() called with winebarrelid=$winebarrelid, density=$density, date=$date');

    final apiPayload = {
      'date': DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(date.toUtc()),
      'density': density,
      'wineId': winebarrelid,
    };
    debugPrint(
        '[ApiManager] Prepared API payload for addFermentationEntry: $apiPayload');

    try {
      await apiService.addFermentationEntry(
        token: token,
        date: date,
        density: density,
        winebarrelid: winebarrelid,
      );
      debugPrint('[ApiManager] Fermentation entry added successfully via API.');

      String wineNameForHistory = winebarrelid;
      try {
        final wineBarrel =
            await apiService.getWineBarrel(winebarrelid, token: token);
        wineNameForHistory = wineBarrel['name'] ?? winebarrelid;
      } catch (fetchError) {
        debugPrint(
            '[ApiManager] Could not fetch wine barrel name for history log: $fetchError');
      }

      final historyEntry = {
        'operationType': 'addFermentationEntry',
        'payload': {
          'date': apiPayload['date'],
          'density': density,
          'wineId': winebarrelid,
          'wineName': wineNameForHistory,
        },
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Synced',
      };
      await historyService.addHistoryEntry(historyEntry);
      debugPrint(
          '[ApiManager] History entry added for successful addFermentationEntry.');
    } catch (e) {
      debugPrint('[ApiManager] Error in addFermentationEntry API call: $e');
      if (e is NoResponseException ||
          e.toString().contains('SocketException')) {
        debugPrint(
            '[ApiManager] Network error detected. Saving addFermentationEntry operation locally.');
        final operation = {
          'operationType': 'addFermentationEntry',
          'payload': jsonEncode(apiPayload),
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
        debugPrint('[ApiManager] Non-network API error. Rethrowing.');
        rethrow;
      }
    }
  }
}

/// Custom exception to indicate an operation failed online but was queued locally.
class OfflineOperationQueuedException implements Exception {
  final String message;
  OfflineOperationQueuedException(this.message);

  @override
  String toString() => 'OfflineOperationQueuedException: $message';
}

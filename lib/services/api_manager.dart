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
  // they update the local cache. If the API call fails (e.g., network error),
  // they attempt to return data from the local cache.
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

  /// Fetch all AdditiveTypes from the server, caching them locally.
  /// On network error, fallback to the locally cached data (if any).
  Future<List<Map<String, dynamic>>> getAllAdditiveTypes(String token) async {
    debugPrint('[ApiManager] getAllAdditiveTypes() called.');
    try {
      final remoteList = await apiService.getAllAdditiveTypes(token: token);
      debugPrint(
          '[ApiManager] Fetched remote additive types: ${remoteList.length} items.');

      // If successful, clear and update the local DB cache.
      await databaseService.clearCachedAdditiveTypes();
      for (final item in remoteList) {
        // Ensure item has 'id' before caching
        if (item['id'] != null) {
          await databaseService.insertOrUpdateAdditiveType(item);
        } else {
          debugPrint(
              '[ApiManager] Warning: Skipping AdditiveType without ID: $item');
        }
      }
      debugPrint('[ApiManager] Additive types cache updated.');
      return remoteList; // Return the fresh data from API
    } catch (e) {
      debugPrint('[ApiManager] Error fetching AdditiveTypes from API: $e');
      // Fallback to local cache if API fails
      debugPrint('[ApiManager] Attempting to return cached AdditiveTypes...');
      final cached = await databaseService.getCachedAdditiveTypes();
      if (cached.isEmpty) {
        debugPrint(
            '[ApiManager] No cached additive types found. Rethrowing error.');
        rethrow; // Rethrow if cache is also empty
      } else {
        debugPrint(
            '[ApiManager] Returning ${cached.length} cached additive types from DB.');
        return cached; // Return cached data
      }
    }
  }

  /// Fetch all WineBarrels from the server, caching them locally (ID and Name only).
  /// On network error, fallback to the locally cached data (if any).
  Future<List<Map<String, dynamic>>> getAllWineBarrelsWithCaching(
      String token) async {
    debugPrint('[ApiManager] getAllWineBarrelsWithCaching() called.');
    try {
      final remoteList = await apiService.getAllWineBarrels(token: token);
      debugPrint(
          '[ApiManager] Fetched remote wine barrels: ${remoteList.length} items.');

      // If successful, clear and update the local DB cache (ID and Name).
      await databaseService.clearCachedWineBarrels();
      for (final item in remoteList) {
        // Ensure item has 'id' before caching
        if (item['id'] != null) {
          // Only cache relevant fields (id, name) according to current DB schema
          final Map<String, dynamic> cacheItem = {
            'id': item['id'],
            'name': item['name'] ??
                'Unbenanntes Fass' // Provide default if name is null
          };
          await databaseService.insertOrUpdateWineBarrel(cacheItem);
        } else {
          debugPrint(
              '[ApiManager] Warning: Skipping WineBarrel without ID: $item');
        }
      }
      debugPrint('[ApiManager] Wine barrels cache updated.');
      return remoteList; // Return the full data fetched from API
    } catch (e) {
      debugPrint('[ApiManager] Error fetching WineBarrels from API: $e');
      // Fallback to local cache if API fails
      debugPrint('[ApiManager] Attempting to return cached WineBarrels...');
      final cached = await databaseService.getCachedWineBarrels();
      if (cached.isEmpty) {
        debugPrint(
            '[ApiManager] No cached wine barrels found. Rethrowing error.');
        rethrow; // Rethrow if cache is also empty
      } else {
        debugPrint(
            '[ApiManager] Returning ${cached.length} cached wine barrels from DB.');
        // IMPORTANT: Returning cached data which currently only has id and name.
        // The UI needs to be aware it might receive less data when offline.
        return cached;
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
    // Ensure required fields are present and have correct types (e.g., IDs as strings)
    final apiPayload = {
      'date': additive['date'] ??
          DateTime.now().toIso8601String(), // Default to now if not provided
      'amountGrammsPerLitre': additive[
          'amountGrammsPerLitre'], // Ensure this key exists and is double/float
      'additiveTypeId': additive['additiveTypeId']
          ?.toString(), // Ensure this key exists and is String (UUID)
      'wineId': additive['wineId']
          ?.toString(), // Ensure this key exists and is String (UUID)
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
      // Attempt to create via API
      final result = await apiService.createAdditive(apiPayload, token: token);
      debugPrint('[ApiManager] Additive created successfully via API: $result');

      // Log to history on success
      final historyEntry = {
        'operationType': 'createAdditive',
        'payload': apiPayload, // Log the payload sent to API
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Synced', // Indicate it was successful online
        'result': result, // Optionally log the API response
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
          'payload': jsonEncode(apiPayload), // Store the payload as JSON string
          'timestamp': DateTime.now().toIso8601String(),
        };
        try {
          await databaseService.insertPendingOperation(operation);
          debugPrint(
              '[ApiManager] createAdditive operation saved locally for later commit.');
          // IMPORTANT: When offline, we cannot return the actual result from the server.
          // Return a placeholder or handle this case in the UI.
          // Here, we rethrow to indicate the online operation failed but was queued.
          // Consider returning a specific status or object indicating offline queuing.
          throw OfflineOperationQueuedException(
              'Create Additive operation queued locally.');
        } catch (dbError) {
          debugPrint(
              '[ApiManager] CRITICAL: Failed to save pending operation locally: $dbError');
          // Rethrow original API error if saving locally fails
          rethrow;
        }
      } else {
        // For other API errors (e.g., 400 Bad Request, 500 Server Error), just rethrow.
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

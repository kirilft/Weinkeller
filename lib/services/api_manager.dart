import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'history_service.dart';

class ApiManager {
  final ApiService apiService;
  final DatabaseService databaseService;
  final HistoryService historyService;

  ApiManager({
    required this.apiService,
    required this.databaseService,
    required this.historyService,
  });

  // -------------------------------
  // Group 1: Safe local for cache
  // -------------------------------

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

  Future<Map<String, dynamic>> getAdditive(int id, String token) async {
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

  /// Fetch all AdditiveTypes from the server, caching them locally.
  /// On network error, fallback to the locally cached data (if any).
  Future<List<Map<String, dynamic>>> getAllAdditiveTypes(String token) async {
    debugPrint('[ApiManager] getAllAdditiveTypes() called.');
    try {
      final remoteList = await apiService.getAllAdditiveTypes(token: token);
      debugPrint(
          '[ApiManager] Fetched remote additive types: ${remoteList.length} items.');
      // If successful, store them in local DB.
      await databaseService.clearCachedAdditiveTypes();
      for (final item in remoteList) {
        await databaseService.insertOrUpdateAdditiveType(item);
      }
      return remoteList;
    } catch (e) {
      debugPrint('[ApiManager] Error in getAllAdditiveTypes: $e');
      // fallback to local cache if offline
      final cached = await databaseService.getCachedAdditiveTypes();
      if (cached.isEmpty) {
        debugPrint('[ApiManager] No cached additive types found.');
        rethrow;
      } else {
        debugPrint(
            '[ApiManager] Returning ${cached.length} cached additive types from DB.');
        return cached;
      }
    }
  }

  // -------------------------------
  // Group 2: Safe to commit later
  // -------------------------------

  /// Creates an additive both online (if possible) and logs it to history.
  /// If offline, the operation is saved to pending operations.
  Future<Map<String, dynamic>> createAdditive(
      Map<String, dynamic> additive, String token) async {
    debugPrint('[ApiManager] createAdditive() called with additive: $additive');
    try {
      // Force conversion to String for the ID fields.
      final adjustedAdditive = {
        'wineId': additive['winebarrelid']?.toString(),
        'additiveTypeId': additive['type']?.toString(),
        'amount': additive['amount'],
        'unit': additive['unit'],
        'addedAt': additive['addedAt'],
      };
      debugPrint('[ApiManager] Adjusted additive: $adjustedAdditive');

      final result =
          await apiService.createAdditive(adjustedAdditive, token: token);
      debugPrint('[ApiManager] Additive created successfully: $result');

      final historyEntry = {
        'operationType': 'createAdditive',
        'payload': adjustedAdditive,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await historyService.addHistoryEntry(historyEntry);
      debugPrint('[ApiManager] History entry added: $historyEntry');
      return result;
    } catch (e) {
      debugPrint('[ApiManager] Error in createAdditive: $e');
      if (e.toString().contains('SocketException') ||
          e is NoResponseException) {
        final operation = {
          'operationType': 'createAdditive',
          'payload': jsonEncode({
            'wineId': additive['winebarrelid']?.toString(),
            'additiveTypeId': additive['type']?.toString(),
            'amount': additive['amount'],
            'unit': additive['unit'],
            'addedAt': additive['addedAt'],
          }),
          'timestamp': DateTime.now().toIso8601String(),
        };
        await databaseService.insertPendingOperation(operation);
        debugPrint(
            '[ApiManager] Operation saved locally for later commit: $operation');
      }
      rethrow;
    }
  }

  /// Updates an additive (if possible) and logs it to history.
  /// If offline, the operation is saved to pending operations.
  Future<void> updateAdditive(
      int id, Map<String, dynamic> additive, String token) async {
    debugPrint(
        '[ApiManager] updateAdditive() called for id: $id with additive: $additive');
    try {
      await apiService.updateAdditive(id, additive, token: token);
      debugPrint('[ApiManager] updateAdditive() succeeded for id: $id');

      final historyEntry = {
        'operationType': 'updateAdditive',
        'payload': {'id': id, 'additive': additive},
        'timestamp': DateTime.now().toIso8601String(),
      };
      await historyService.addHistoryEntry(historyEntry);
      debugPrint('[ApiManager] History entry added: $historyEntry');
    } catch (e) {
      debugPrint('[ApiManager] Error in updateAdditive: $e');
      if (e.toString().contains('SocketException') ||
          e is NoResponseException) {
        final operation = {
          'operationType': 'updateAdditive',
          'payload': jsonEncode({'id': id, 'additive': additive}),
          'timestamp': DateTime.now().toIso8601String(),
        };
        await databaseService.insertPendingOperation(operation);
        debugPrint(
            '[ApiManager] Operation saved locally for later commit: $operation');
      }
      rethrow;
    }
  }

  /// Adds a fermentation entry both online (if possible) and logs it to history.
  /// If offline, the operation is saved to pending operations.
  Future<void> addFermentationEntry(
      String token, DateTime date, double density, String winebarrelid) async {
    debugPrint(
        '[ApiManager] addFermentationEntry() called with winebarrelid=$winebarrelid, density=$density, date=$date');
    try {
      // Fetch wine barrel name for history logging.
      final wineBarrel =
          await apiService.getWineBarrel(winebarrelid, token: token);
      final wineName = wineBarrel['name'] ?? 'Unbekannt';

      await apiService.addFermentationEntry(
        token: token,
        date: date,
        density: density,
        winebarrelid: winebarrelid,
      );
      debugPrint('[ApiManager] Fermentation entry added successfully.');

      final historyEntry = {
        'operationType': 'addFermentationEntry',
        'payload': {
          'date': DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(date),
          'density': density,
          'wineId': wineName, // saving the barrel's name here
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
      await historyService.addHistoryEntry(historyEntry);
      debugPrint('[ApiManager] History entry added: $historyEntry');
    } catch (e) {
      debugPrint('[ApiManager] Error in addFermentationEntry: $e');
      if (e.toString().contains('SocketException') ||
          e is NoResponseException) {
        final operation = {
          'operationType': 'addFermentationEntry',
          'payload': jsonEncode({
            'date': DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(date),
            'density': density,
            'wineId': winebarrelid,
          }),
          'timestamp': DateTime.now().toIso8601String(),
        };
        await databaseService.insertPendingOperation(operation);
        debugPrint(
            '[ApiManager] Operation saved locally for later commit: $operation');
      }
      rethrow;
    }
  }
}

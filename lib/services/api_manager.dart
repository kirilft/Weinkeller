import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'history_service.dart';

class ApiManager {
  final ApiService apiService;
  final DatabaseService databaseService;
  final HistoryService historyService; // New dependency

  ApiManager({
    required this.apiService,
    required this.databaseService,
    required this.historyService,
  });

  // -------------------------------
  // Group 1: Safe local for cache
  // -------------------------------

  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final result = await apiService.getCurrentUser(token: token);
      return result;
    } catch (e) {
      debugPrint('[ApiManager] Error in getCurrentUser: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAdditive(int id, String token) async {
    try {
      final result = await apiService.getAdditive(id, token: token);
      return result;
    } catch (e) {
      debugPrint('[ApiManager] Error in getAdditive: $e');
      rethrow;
    }
  }

  /// Fetch all AdditiveTypes from the server, caching them locally.
  /// On network error, fallback to the locally cached data (if any).
  Future<List<Map<String, dynamic>>> getAllAdditiveTypes(String token) async {
    try {
      // Attempt remote fetch.
      final remoteList = await apiService.getAllAdditiveTypes(token: token);
      // If successful, store them in local DB.
      await databaseService.clearCachedAdditiveTypes();
      for (final item in remoteList) {
        // item includes {id, type}
        await databaseService.insertOrUpdateAdditiveType(item);
      }
      return remoteList;
    } catch (e) {
      debugPrint('[ApiManager] Error in getAllAdditiveTypes: $e');
      // fallback to local cache if offline
      final cached = await databaseService.getCachedAdditiveTypes();
      if (cached.isEmpty) {
        rethrow;
      } else {
        debugPrint('[ApiManager] Returning cached additive types from DB');
        return cached;
      }
    }
  }

  // -------------------------------
  // Group 2: Safe to commit later
  // -------------------------------

  Future<Map<String, dynamic>> createAdditive(
      Map<String, dynamic> additive, String token) async {
    try {
      final result = await apiService.createAdditive(additive, token: token);
      // Log history after successful commit
      final historyEntry = {
        'operationType': 'createAdditive',
        'payload': additive,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await historyService.addHistoryEntry(historyEntry);
      return result;
    } catch (e) {
      debugPrint('[ApiManager] Error in createAdditive: $e');
      if (e.toString().contains('SocketException') ||
          e is NoResponseException) {
        final operation = {
          'operationType': 'createAdditive',
          'payload': jsonEncode(additive),
          'timestamp': DateTime.now().toIso8601String(),
        };
        await databaseService.insertPendingOperation(operation);
        debugPrint(
            '[ApiManager] Operation saved locally for later commit: $operation');
      }
      rethrow;
    }
  }

  Future<void> updateAdditive(
      int id, Map<String, dynamic> additive, String token) async {
    try {
      await apiService.updateAdditive(id, additive, token: token);
      // Log history after successful update
      final historyEntry = {
        'operationType': 'updateAdditive',
        'payload': {'id': id, 'additive': additive},
        'timestamp': DateTime.now().toIso8601String(),
      };
      await historyService.addHistoryEntry(historyEntry);
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

  Future<void> addFermentationEntry(
      String token, DateTime date, double density, String wineId) async {
    try {
      await apiService.addFermentationEntry(
          token: token, date: date, density: density, wineId: wineId);
      // Log history after successful commit
      final historyEntry = {
        'operationType': 'addFermentationEntry',
        'payload': {
          'date': DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(date),
          'density': density,
          'wineId': wineId,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
      await historyService.addHistoryEntry(historyEntry);
    } catch (e) {
      debugPrint('[ApiManager] Error in addFermentationEntry: $e');
      if (e.toString().contains('SocketException') ||
          e is NoResponseException) {
        final operation = {
          'operationType': 'addFermentationEntry',
          'payload': jsonEncode({
            'date': DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(date),
            'density': density,
            'wineId': wineId,
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

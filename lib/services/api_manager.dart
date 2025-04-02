import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'package:intl/intl.dart';

class ApiManager {
  final ApiService apiService;
  final DatabaseService databaseService;

  ApiManager({required this.apiService, required this.databaseService});

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

  // -------------------------------
  // Group 2: Safe to commit later
  // -------------------------------

  Future<Map<String, dynamic>> createAdditive(
      Map<String, dynamic> additive, String token) async {
    try {
      final result = await apiService.createAdditive(additive, token: token);
      return result;
    } catch (e) {
      debugPrint('[ApiManager] Error in createAdditive: $e');
      if (e is NoResponseException ||
          e.toString().contains('SocketException')) {
        final operation = {
          'operationType': 'createAdditive',
          'payload': additive,
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
    } catch (e) {
      debugPrint('[ApiManager] Error in updateAdditive: $e');
      if (e is NoResponseException ||
          e.toString().contains('SocketException')) {
        final operation = {
          'operationType': 'updateAdditive',
          'payload': {
            'id': id,
            'additive': additive,
          },
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
    } catch (e) {
      debugPrint('[ApiManager] Error in addFermentationEntry: $e');
      if (e is NoResponseException ||
          e.toString().contains('SocketException')) {
        final operation = {
          'operationType': 'addFermentationEntry',
          'payload': {
            'date': DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(date),
            'density': density,
            'wineId': wineId,
          },
          'timestamp': DateTime.now().toIso8601String(),
        };
        await databaseService.insertPendingOperation(operation);
        debugPrint(
            '[ApiManager] Operation saved locally for later commit: $operation');
      }
      rethrow;
    }
  }

  // Optionally, you can add similar safe commit methods for deletion or other actions.
}
